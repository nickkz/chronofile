#libs
library(RCurl)
library(jsonlite)
library(plyr)
library(RQuantLib)
library(httr)
library(quantmod)
library(PerformanceAnalytics)
library(urca)
library(RMySQL)

#fixJSON output
fixJSON <- function(json_str){
  stuff = c('cid','cp','s','cs','vol','expiry','underlying_id','underlying_price',
            'p','c','oi','e','b','strike','a','name','puts','calls','expirations',
            'y','m','d')
  
  for(i in 1:length(stuff)){
    replacement1 = paste(',"', stuff[i], '":', sep = "")
    replacement2 = paste('\\{"', stuff[i], '":', sep = "")
    regex1 = paste(',', stuff[i], ':', sep = "")
    regex2 = paste('\\{', stuff[i], ':', sep = "")
    json_str = gsub(regex1, replacement1, json_str)
    json_str = gsub(regex2, replacement2, json_str)
  }
  return(json_str)
}

#gets option quote from google
getOptionQuote <- function(symbol){
  output = list()
  url = paste('http://www.google.com/finance/option_chain?q=', symbol, '&output=json', sep = "")
  x = getURL(url)
  fix = fixJSON(x)
  json = fromJSON(fix)
  numExp = dim(json$expirations)[1]
  for(i in 1:numExp){
    # download each expirations data
    y = json$expirations[i,]$y
    m = json$expirations[i,]$m
    d = json$expirations[i,]$d
    expName = paste(y, m, d, sep = "_")
    if (i > 1){
      url = paste('http://www.google.com/finance/option_chain?q=', symbol, '&output=json&expy=', y, '&expm=', m, '&expd=', d, sep = "")
      json = fromJSON(fixJSON(getURL(url)))
    }
    output[[paste(expName, "calls", sep = "_")]] = json$calls
    output[[paste(expName, "puts", sep = "_")]] = json$puts
  }
  return(output)
}

#calculate historical vol
url = paste('http://www.google.com/finance/historical?q=NASDAQ:QQQ&startdate=Jan+01+2015&enddate=June+01+2015&output=csv', sep = "")
df <- read.csv (url)

tickers = c("^N225", "^OEX", "AAPL", "IBM", "MSFT", "AAPL160115C00057140")
myEnv <- new.env()
getSymbols(tickers, src='yahoo', from = "2015-01-01", env = myEnv)
index <- do.call(merge, c(eapply(myEnv, Ad), all=FALSE))
msft_price <- as.numeric(index$MSFT.Adjusted[nrow(index)])

#Calculate daily returns for all indices and convert to arithmetic returns
index.ret <- exp(CalculateReturns(index,method="compound")) - 1
index.ret[1,] <- 0
head(index.ret)

#Calculate realized volatility
#realizedvol <- rollapply(index.ret, width = 20, FUN=sd.annualized)
#head(realizedvol, 25)
realized.vol <- xts(apply(index.ret,2,runSD,n=30), index(index.ret))*sqrt(252)
head(realized.vol, 50)
plot(realized.vol$MSFT.Adjusted)

ratio_series <- na.omit(realized.vol$IBM.Adjusted / realized.vol$OEX.Adjusted)
df=ur.df(ratio_series,type="none",lags=0)
summary(df)
plot(ratio_series)

msft_opt = getOptionQuote("MSFT")
# this might take a few seconds to complete depending on your connection with Google
# now lets plot the open interest by strike for the 4/17/2015 puts
plot(
    msft_opt$"2015_12_18_puts"$strike, 
    msft_opt$"2015_12_18_puts"$oi, 
    type = "s", 
    main = "Open Interest by Strike",
    col = "red"
  )
msft_opt

EO <- EuropeanOption("call", 100, 100, 0.01, 0.03, 0.5, 0.4)
summary(EO)

puts <- as.data.frame(msft_opt$"2015_12_18_puts")
puts$strike
EOImpVol <- EuropeanOptionImpliedVolatility(type = "put", value=12.14, underlying = 100, strike = 100, dividendYield = 0.01, riskFreeRate = 0.03, maturity = 0.5, volatility =  0.4)
EOImpVol[1]
puts$ivol <- EuropeanOptionImpliedVolatility("put", puts$p, msft_last, puts$strike, 0, 0.01, 0.25, 0.4)
aapl_price <- 127.50

#filter to all puts
puts_filter = subset(puts, as.numeric(p) > 0 & as.numeric(strike) >= 0.8 * msft_price & as.numeric(strike) <= 1.2 * msft_price)
puts_filter$ivol <- by(
  puts_filter, 
  1:nrow(puts_filter), 
  function(row) { 
    EuropeanOptionImpliedVolatility(
      type = "put", 
      value=max(0.01, as.numeric(row$p)), 
      underlying = msft_price, 
      strike = max(msft_price * 0.9, min(msft_price * 1.1, as.numeric(row$strike))), 
      dividendYield = 0.01, 
      riskFreeRate = 0.01, 
      maturity = 0.26, 
      volatility =  0.1
    )[1]
  } 
)

#calculate iv
for(i in 1:nrow(puts_filter)) {
  cat ("Calculating Row ", i, puts_filter[i, "s"], "\n")
  price <- (as.numeric(puts_filter[i, "b"]) + as.numeric(puts_filter[i, "a"])) / 2
  iv <- EuropeanOptionImpliedVolatility(
    type = "put", 
    value=price, 
    underlying = aapl_price, 
    strike = as.numeric(puts_filter[i, "strike"]), 
    dividendYield = 0.01, 
    riskFreeRate = 0.01, 
    maturity = 0.1, 
    volatility =  0.5
  )[1]
  puts_filter[i, "ivol"] = iv
}

puts_filter$ivol = 0

msft_opt = getOptionQuote("MSFT")
qqq_opt = getOptionQuote("QQQ")
attributes(qqq_opt)


#write option list to mysql
con <- dbConnect(MySQL(),
                 user = 'root',
                 password = 'link',
                 host = 'localhost',
                 dbname='volarb')
dbWriteTable(conn = con, name = 'popt', value = puts_filter, append=TRUE)

#load option files
setwd("C:\\dev\\volarb\\options")
start_date <- 20131101
end_date <- 20131130
option_ts <- NULL
for (file_date in start_date:end_date) {
  option_file <- paste0("L3_optionstats_", file_date, ".csv")
  cat("Processing File", option_file, "...\n")
  if (file.exists(option_file)) {
    option_stats <- read.csv(option_file)
    print(head(option_stats, 1))
    option_stats_OEX <- subset(option_stats, symbol=="OEX")
    OEX_iv30mean <- option_stats_OEX$iv30mean
    option_stats$iv30meanOEX <- option_stats$iv30mean / OEX_iv30mean
    if (is.null(option_ts)) {
      option_ts <- option_stats
    } else {
      option_ts <- rbind(option_ts, option_stats)
    }
  }
}

option_stats_AAPL <- subset(option_ts, symbol=="AAPL")
option_stats_NVDA <- subset(option_ts, symbol=="NVDA")
option_stats_GOOGL <- subset(option_ts, symbol=="GOOGL")
option_stats_NFLX <- subset(option_ts, symbol=="NFLX")

g_range <- range(0, option_stats_AAPL$iv30meanOEX, option_stats_NVDA$iv30meanOEX, option_stats_GOOGL$iv30meanOEX, option_stats_NFLX$iv30meanOEX)
plot(option_stats_AAPL$iv30meanOEX, type="l", col="red", ylim=g_range)
lines(option_stats_NVDA$iv30meanOEX, type="l", col="blue")
lines(option_stats_GOOGL$iv30meanOEX, type="l", col="purple")
lines(option_stats_NFLX$iv30meanOEX, type="l", col="green")

legend(1, g_range[2], c("AAPL","NVDA", "GOOGL", "NFLX"), cex=0.8, 
       col=c("red","blue", "purple", "green"), pch=21:22, lty=1:2);

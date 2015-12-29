DELIMITER |

DROP FUNCTION IF EXISTS fnGetProductID;
DROP FUNCTION IF EXISTS fnGetSecID;
CREATE FUNCTION fnGetSecID(
	mysectype VARCHAR(20), 
	mysecsubtype VARCHAR(20), 
	myexchange VARCHAR(20), 
	myprimaryexchange VARCHAR(20), 
	myticker VARCHAR(20)
) returns INT
BEGIN
	DECLARE secID INT;
	DECLARE exchangeID INT;
	set exchangeID = 
	(
		select 
			exchange_id 
		from 
			exchange e
		where 
			e.exchange = myexchange
	);
	
	if (exchangeID is null) then
		set secID = -1;
	else
		set secID = 
		(
			select 
				security_id 
			from 
				security s
				join sec_type st on st.sec_type_id = s.sec_type
				join exchange e on s.exchange = e.exchange_id
				left join exchange pe on s.primary_exchange = pe.exchange_id
			where 
				st.sec_type = mysectype
				and (mysecsubtype is null or st.sec_sub_type = mysecsubtype)
				and ticker = myticker
				and e.exchange = myexchange
				and (myprimaryexchange is null or pe.exchange = myprimaryexchange)
		);

		IF (secID is null) THEN
			BEGIN

				DECLARE secTypeID, exchangeID, primaryExchangeID INT;
				select sec_type_id from sec_type st where st.sec_type = mysectype and st.sec_sub_type = mysecsubtype into secTypeID;
				select exchange_id from exchange e where e.exchange = myexchange into exchangeID;
				IF (myprimaryexchange is null) THEN
					set primaryExchangeID = NULL;
				ELSE
					select exchange_id from exchange pe where pe.exchange = myprimaryexchange into primaryExchangeID;
				END IF;

				INSERT security (
					sec_type,
					exchange,
					primary_exchange,
					ticker,
					date_added
				) VALUES (
					secTypeID,
					exchangeID,
					primaryExchangeID,
					myticker, 
					NOW()
				);
				set secID = last_insert_id();
			END;
		END IF;
	
	end if;
	
	return secID;
END
|
DROP FUNCTION IF EXISTS fnInsertSecDaily;
CREATE FUNCTION fnInsertSecDaily(
	myexchange VARCHAR(20), 
	myprimaryexchange VARCHAR(20), 
	myticker VARCHAR(20),
    mydaily_time datetime,
    myopen decimal(12,4),
    myhigh decimal(12,4),
    mylow decimal(12,4),
    myclose decimal(12,4),
    myadjclose decimal(12,4),
    myvolume int
) returns INT
BEGIN
	DECLARE secID INT;
	DECLARE exchangeID INT;
	DECLARE dailyID INT;
	set exchangeID = 
	(
		select 
			exchange_id 
		from 
			exchange e
		where 
			e.exchange = myexchange
	);
	
	if (exchangeID is null) then
		set dailyID = -1;
	else
		set secID = fnGetSecID('Equity', 'Ord', myexchange, myprimaryexchange, myticker);
		insert sec_daily (
			security_id, 
			exchange_id,
            daily_time,
			open_px,
			high_px,
			low_px,
			close_px,
			adj_close,
            volume,
			date_added
	    ) values (
			secID,
			exchangeID,
			mydaily_time, 
			myopen,
			myhigh,
			mylow,
			myclose,
			myadjclose,
            myvolume,
			now()
	    );
        set dailyID = last_insert_id();
	end if;
    return dailyID;
END
|
DROP FUNCTION IF EXISTS fnInsertSecFundamental;
CREATE FUNCTION fnInsertSecFundamental(
	myexchange VARCHAR(20), 
	myprimaryexchange VARCHAR(20), 
	myticker VARCHAR(20),
    myfundamental_time datetime,

	-- Stats
	myOneyrTargetPrice numeric (12, 4),
	myMarketCapitalization varchar(12),
	myAverageDailyVolume numeric (12, 4),
    
	-- MAs
	myFiftydayMovingAverage numeric (12, 4),
	myChangeFromFiftydayMovingAverage numeric (12, 4),
	myPercentChangeFromFiftydayMovingAverage numeric (12, 4),
	myTwoHundreddayMovingAverage numeric (12, 4),
	myChangeFromTwoHundreddayMovingAverage numeric (12, 4),
	myPercentChangeFromTwoHundreddayMovingAverage numeric (12, 4),

	-- Earnings
	myEarningsShare numeric (12, 4),
	myEPSEstimateCurrentYear numeric (12, 4),
	myEPSEstimateNextQuarter numeric (12, 4),
	myEPSEstimateNextYear numeric (12, 4),
	myPriceEPSEstimateCurrentYear numeric (12, 4),
	myPriceEPSEstimateNextYear numeric (12, 4),

	-- Dividends
	myDividendPayDate varchar(12),
	myDividendYield numeric (12, 4),
	myExDividendDate varchar(12),
	myDividendShare numeric (12, 4),
    
    -- Ratios
	myBookValue numeric (12, 4),
	myPriceSales numeric (12, 4),
	myPERatio numeric (12, 4),
	myPEGRatio numeric (12, 4),
	myShortRatio numeric (12, 4)
) returns INT
BEGIN
	DECLARE secID INT;
	DECLARE exchangeID INT;
	DECLARE fundamentalID INT;
	set exchangeID = 
	(
		select 
			exchange_id 
		from 
			exchange e
		where 
			e.exchange = myexchange
	);
	
	if (exchangeID is null) then
		set fundamentalID = -1;
	else
		set secID = fnGetSecID('Equity', 'Ord', myexchange, myprimaryexchange, myticker);
		insert sec_fundamental (
			security_id, 
			exchange_id,
            fundamental_time,

			-- Stats
			OneyrTargetPrice,
			MarketCapitalization,
			AverageDailyVolume,
			
			-- MAs
			FiftydayMovingAverage,
			ChangeFromFiftydayMovingAverage,
			PercentChangeFromFiftydayMovingAverage,
			TwoHundreddayMovingAverage,
			ChangeFromTwoHundreddayMovingAverage,
			PercentChangeFromTwoHundreddayMovingAverage,

			-- Earnings
			EarningsShare,
			EPSEstimateCurrentYear,
			EPSEstimateNextQuarter,
			EPSEstimateNextYear,
			PriceEPSEstimateCurrentYear,
			PriceEPSEstimateNextYear,

			-- Dividends
			DividendPayDate,
			DividendYield,
			ExDividendDate,
			DividendShare,
			
			-- Ratios
			BookValue,
			PriceSales,
			PERatio,
			PEGRatio,
			ShortRatio,

			date_added
	    ) values (
			secID,
			exchangeID,
			myfundamental_time, 

			-- Stats
			myOneyrTargetPrice,
			myMarketCapitalization,
			myAverageDailyVolume,
			
			-- MAs
			myFiftydayMovingAverage,
			myChangeFromFiftydayMovingAverage,
			myPercentChangeFromFiftydayMovingAverage,
			myTwoHundreddayMovingAverage,
			myChangeFromTwoHundreddayMovingAverage,
			myPercentChangeFromTwoHundreddayMovingAverage,

			-- Earnings
			myEarningsShare,
			myEPSEstimateCurrentYear,
			myEPSEstimateNextQuarter,
			myEPSEstimateNextYear,
			myPriceEPSEstimateCurrentYear,
			myPriceEPSEstimateNextYear,

			-- Dividends
			myDividendPayDate,
			myDividendYield,
			myExDividendDate,
			myDividendShare,
			
			-- Ratios
			myBookValue,
			myPriceSales,
			myPERatio,
			myPEGRatio,
			myShortRatio,

			now()
	    );
        set fundamentalID = last_insert_id();
	end if;
    return fundamentalID;
END
|
DROP PROCEDURE IF EXISTS spInsertOrder;
|
CREATE PROCEDURE spInsertOrder(
	myorder_id int(8),  
	mysecurity_id int(8),  
	myorder_type varchar(10),
	myside varchar(10),
	myqty int,
	myprice numeric (12, 4),
	mystrategy varchar(20)
)
BEGIN
    IF ((select count(*) from orders where order_id = myorder_id) = 0) then
    
	     insert orders (
				order_id,
				strategy_instance_id,
				security_id, 
				order_type,
				side,
				qty,
				price,
				strategy,
				date_added
	     ) values (
				myorder_id,
				0,
				mysecurity_id, 
				myorder_type,
				myside,
				myqty,
				myprice,
				mystrategy,
				now()
	     );

     else
	     	update 
	     		orders
	     	set
	     		security_id = mysecurity_id,
	     		order_type = myorder_type,
	     		side = myside,
	     		qty = myqty,
	     		price = myprice,
	     		strategy = mystrategy
	     	where
	     		order_id = myorder_id;
     
     end if;

END;
|
DELIMITER ;

 #select fnGetSecID('Equity', 'Ord', 'NASDAQ', 'SMART', 'MSFT');
 #select fnGetSecID('Equity', 'Ord', 'NASDAQ', 'SMART', 'TSLA');
 #select fnGetSecID('Equity', 'Ord', 'NASDAQ', 'SMART', 'GOOG');
 #select fnInsertSecDaily('NASDAQ', 'SMART', 'GOOG', '2015-10-01', 650.01, 651.02, 652.03, 653.04, 654.05, 12000);
 select fnInsertSecFundamental(
	'NASDAQ', 'SMART', 'GOOG', '2015-12-27', 
	1.0, '200B', 2, 
    2.0, 3.0, 4.0, 5.0, 6.0, 7.0,
    8.0, 9.0, 10.0, 11.0, 12.0, 13.0,
    'test', null, 'test2', 15.0,
    16.0, 17.0, 18.0, 19.0, null
    );

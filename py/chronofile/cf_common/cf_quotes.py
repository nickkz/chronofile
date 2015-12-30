'''
Created on Dec 23, 2015

@author: nick
'''

#Constants
DATE_FMT = '%Y-%m-%d'
TIME_FMT = '%H:%M:%S'
DEBUG = False
INFO = True
DB_HOST = ''
DB_USER = ''
DB_PASSWORD = ''
DB_DATABASE = ''

#Imports
import pymysql.cursors
import yql
import urllib

from numpy import *
from numpy.random import permutation
from pandas import DataFrame, Series
from pandas.io.data import DataReader
#from pandas_datareader import data, wb
from datetime import datetime
from yahoo_finance import Share
try: import simplejson as json
except ImportError: import json
try: from cf_config_dev import *
except ImportError: pass

def print_debug(self, txt):
    if DEBUG == True:
        print (txt)
        
def print_info(self, txt):
    if INFO == True:
        print (txt)    

class Quote(object):
   
    def __init__(self):
        self.symbol = ''
        self.date,self.open_,self.high,self.low,self.close,self.volume,self.adj_close = ([] for _ in range(7))
        print_debug (self, 'Init Base Quote')

    def query(self):
        print_info (self, 'Processing ' + self.symbol + " Historical Quotes")
        today = datetime.now()
        firstOfMonth = datetime(today.year, today.month, 1)
        tickerDR = DataReader(self.symbol,  'yahoo', firstOfMonth, today)
        print_debug(self, tickerDR)

        try:
            print_debug (self, '\nOpening Connection to MySQL')
            connection = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, db=DB_DATABASE, charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor)
            print_debug(self, connection)
        
            for i in range(len(tickerDR)):
                print_debug(self, "\nProcessing Data")
                self.date.append(str(tickerDR.index[i]))
                self.open_.append(float(tickerDR['Open'][i]))
                self.high.append(float(tickerDR['High'][i]))
                self.low.append(float(tickerDR['Low'][i]))
                self.close.append(float(tickerDR['Close'][i]))
                self.volume.append(int(tickerDR['Volume'][i]))            
                self.adj_close.append(float(tickerDR['Adj Close'][i]))
                with connection.cursor() as cursor:
                    sql = "select fnInsertSecDaily('NASDAQ', 'SMART', %s, %s, %r, %r, %r, %r, %r, %r);"
                    retVal = cursor.execute(sql, (self.symbol, str(tickerDR.index[i]), float(tickerDR['Open'][i]), float(tickerDR['High'][i]), float(tickerDR['Low'][i]), float(tickerDR['Close'][i]), float(tickerDR['Adj Close'][i]), int(tickerDR['Volume'][i])))
                    print_debug (self, "Returned " + str(retVal))
            
                connection.commit()
        finally:
            print_debug (self, 'Closing Connection to MySQL')
            connection.close()
                
            
    def __repr__(self):
        return self.symbol

class YahooQuote(Quote):
    ''' Daily quotes from Yahoo. Date format='yyyy-mm-dd' '''
    def __init__(self,symbol,start_date,end_date=datetime.today().isoformat()):
        super(YahooQuote, self).__init__()
        self.symbol = symbol.upper()
        print_debug (self, 'Init ' + self.symbol)

class QueryError(Exception):

    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)

class YahooStockInfo(object):
    
    PUBLIC_API_URL = 'http://query.yahooapis.com/v1/public/yql'
    DATATABLES_URL = 'store://datatables.org/alltableswithkeys'
    HISTORICAL_URL = 'http://ichart.finance.yahoo.com/table.csv?s='
    RSS_URL = 'http://finance.yahoo.com/rss/headline?s='
    FINANCE_TABLES = {'quotes': 'yahoo.finance.quotes',
                     'options': 'yahoo.finance.options',
                     'quoteslist': 'yahoo.finance.quoteslist',
                     'sectors': 'yahoo.finance.sectors',
                     'industry': 'yahoo.finance.industry'}    

    def __convert_float(self, txt):
        if (isinstance(txt, float)):
            return float(txt)
        else:
            return -1

    def __init__(self,symbol,start_date,end_date=datetime.today().isoformat()):
        self.symbol = symbol
        print_debug (self, 'Init Base Info for ' + symbol)
        #stuff = self.get_current_info(symbol.split(), ['PERatio', 'DividendYield', 'EarningsShare', 'EPSEstimateNextQuarter', 'FiftydayMovingAverage', 'OneyrTargetPrice', 'PercentChange'])
        stockInfo = self.get_current_info(symbol.split())
        print_debug (self, stockInfo)
        print_debug (self, stockInfo['EPSEstimateNextQuarter'])
        print_debug (self, 'Open Connection to MySQL ' + DB_HOST + ' User ' + DB_USER + ' DB ' + DB_DATABASE)
        connection = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, db=DB_DATABASE, charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor)
        print_debug(self, connection)
        
        try:
            with connection.cursor() as cursor:
                sql = "select fnInsertSecFundamental('NASDAQ', 'SMART', %s, '2015-12-27', %r, %s, %r, %r, %r, %r, %r, %r, %r, %r, %r, %r, %r, %r, %r, %s, %r, %s, %r, %r, %r, %r, %r, %r);"
                print_debug(self, sql)
                retVal = cursor.execute(sql, (self.symbol, \
                                              self.__convert_float(stockInfo['OneyrTargetPrice']), str(stockInfo['MarketCapitalization']), self.__convert_float(stockInfo['AverageDailyVolume']), \
                                              self.__convert_float(stockInfo['FiftydayMovingAverage']), self.__convert_float(stockInfo['ChangeFromFiftydayMovingAverage']), self.__convert_float(stockInfo['PercentChangeFromFiftydayMovingAverage'].replace("%", "")), \
                                              self.__convert_float(stockInfo['TwoHundreddayMovingAverage']), self.__convert_float(stockInfo['ChangeFromTwoHundreddayMovingAverage']), self.__convert_float(stockInfo['PercentChangeFromTwoHundreddayMovingAverage'].replace("%", "")), \
                                              self.__convert_float(stockInfo['EarningsShare']), self.__convert_float(stockInfo['EPSEstimateCurrentYear']), self.__convert_float(stockInfo['EPSEstimateNextQuarter']), \
                                              self.__convert_float(stockInfo['EPSEstimateNextYear']), self.__convert_float(stockInfo['PriceEPSEstimateCurrentYear']), float(stockInfo['PriceEPSEstimateNextYear']), \
                                              str(stockInfo['DividendPayDate']), self.__convert_float(stockInfo['DividendYield']), str(stockInfo['ExDividendDate']), \
                                              self.__convert_float(stockInfo['DividendShare']), self.__convert_float(stockInfo['BookValue']), self.__convert_float(stockInfo['PriceSales']), \
                                              self.__convert_float(stockInfo['PERatio']), self.__convert_float(stockInfo['PEGRatio']), self.__convert_float(stockInfo['ShortRatio'])))
                print_debug (self, "Returned " + str(retVal))
                connection.commit()

        finally:
            print_debug (self, 'Close Connection to MySQL')
            connection.close()                    

    def __format_symbol_list(self, symbolList):
        return ",".join(["\""+stock+"\"" for stock in symbolList])

    def __is_valid_response(self, response, field):
        return 'query' in response and 'results' in response['query'] \
            and field in response['query']['results']

    def __validate_response(self, response, tagToCheck):
        if self.__is_valid_response(response, tagToCheck):
            quoteInfo = response['query']['results'][tagToCheck]
        else:
            if 'error' in response:
                raise self.QueryError('YQL query failed with error: "%s".'
                    % response['error']['description'])
            else:
                raise self.QueryError('YQL response malformed.')
        return quoteInfo

    def executeYQLQuery(self, yql):
        #conn = httplib.HTTPConnection('query.yahooapis.com')
        queryString = urllib.parse.urlencode({'q': yql, 'format': 'json', 'env': YahooStockInfo.DATATABLES_URL})
        #conn.request('GET', YahooStockInfo.PUBLIC_API_URL + '?' + queryString)
        print_debug (self, "Loading " + YahooStockInfo.PUBLIC_API_URL + '?' + queryString)
        return json.loads(urllib.request.urlopen(YahooStockInfo.PUBLIC_API_URL + '?' + queryString).read())

    def get_current_info(self, symbolList, columnsToRetrieve='*'):
        """Retrieves the latest data (15 minute delay) for the
        provided symbols."""
    
        columns = ','.join(columnsToRetrieve)
        symbols = self.__format_symbol_list(symbolList)
    
        yql = 'select %s from %s where symbol in (%s)' \
              %(columns, YahooStockInfo.FINANCE_TABLES['quotes'], symbols)
        response = self.executeYQLQuery(yql)
        return self.__validate_response(response, 'quote')

      
if __name__ == '__main__':
    pass

print ('Init Main')
tickers = ['NFLX', 'GOOG', 'TSLA', 'AAPL', 'MSFT', 'NVDA']
for ticker in tickers:
    today = datetime.now()
    firstOfMonth = datetime(today.year, today.month, 1)
    print ('\nProcessing ' + ticker + ' Fundamental Data from ' + firstOfMonth.strftime(DATE_FMT))
    ysi = YahooStockInfo(ticker, firstOfMonth)
    yq = YahooQuote(ticker, firstOfMonth)
    yq.query()

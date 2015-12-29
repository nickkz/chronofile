'''
Created on Dec 21, 2015

@author: nick
'''
import numpy
import pandas
#import pandas_datareader
import sys

from numpy import *
from numpy.random import permutation

from pandas import DataFrame, Series
from pandas.io.data import DataReader
#from pandas_datareader import data, wb
from datetime import datetime

from yahoo_finance import Share

if __name__ == '__main__':
    pass

print ("My paths")
print('\n'.join(sorted(sys.path)))

#numpy test
print ("numpy test")
for num in range(10,20):
    print(permutation(4))
print ("\n\n")
#pandas test
print ("pandas test")
df = DataFrame({'int_col' : [1,2,6,8,-1], 'float_col' : [0.1, 0.2,0.2,10.1,None], 'str_col' : ['a','b',None,'c','a']})
print(df)

#yahoo finance
#yahoo = Share('YHOO')
#nflx = Share('NFLX')
#aapl = Share('AAPL')
#print ("\n\nYHOO:")
#print (yahoo.get_open())
#nflx.refresh()
#print (nflx.get_open())
#print (aapl.get_open())
#print(nflx.get_historical('2015-04-25', '2015-04-29'))

tickers = ['NFLX', 'GOOG', 'TSLA', 'AAPL', 'MSFT']
for ticker in tickers:
    print ('\nProcessing ' + ticker + ': (Open High Low)')
    tickerDR = DataReader('NFLX',  'yahoo', datetime(2015,12,1), datetime(2015,12,23))
    #open = nflx[['Open', 'High', 'Low', 'Close', 'Adj Close']]
    #print ('Length: ' + str(len(open))) 
    #print (open[0:5])
    #print (open['Open'][1])
    print('\n')
    for i in range(len(tickerDR)):
        print (str(tickerDR.index[i]) + ',' + str(tickerDR['Open'][i]) + ',' + str(tickerDR['High'][i]) + ',' + str(tickerDR['Low'][i]))

#print(ibm['Adj Close', 1])

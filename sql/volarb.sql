/*
	Running this file will (re)create database schema for volarb tables 
	It will also populate with some sample data
	
*/

create database IF not EXISTS volarb;
use volarb;

/* Security Type table will contain both a "type" and "subtype" to make for easier querying */

DROP TABLE IF EXISTS popt;
CREATE TABLE popt (  
	popt_id int(8) NOT NULL AUTO_INCREMENT,  
	row_names int(8),
	cid varchar(32), 
	name varchar(32),
	s varchar(32),
	e varchar(10),
	p DECIMAL(13,2),
	cs varchar(12),
	c DECIMAL(13,2),
	cp DECIMAL(13,2),
	b DECIMAL(13,2),
	a DECIMAL(13,2),
	oi int,
	vol int,
	strike DECIMAL(13,2),
	expiry date,
	ivol DECIMAL(13,4),
	date_added timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	date_modified datetime,
	PRIMARY KEY (popt_id),  
	UNIQUE id (popt_id)
);

insert popt (cid, name, s, e, p, cs, c, cp, b, a, oi, vol, strike, expiry, ivol) 
values ('236482771609557', 'AAPL', 'AAPL151218P00105000', 'OPRA', 1.75, 'chb', 0.0, 0.0, 1.67, 1.73, 900, 73, 105.0, STR_TO_DATE('Dec 18, 2015', '%b %d, %Y'), 0.0);

DROP TABLE IF EXISTS sec_type;
CREATE TABLE sec_type (  
	sec_type_id int(8) NOT NULL AUTO_INCREMENT,  
	sec_type varchar(12), 
	sec_sub_type varchar(12),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (sec_type_id),  
	UNIQUE id (sec_type_id)
);

insert sec_type (sec_type, sec_sub_type, date_added) values ('Equity', 'Ord', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('Equity', 'Adr', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('FX', 'Direct', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('FX', 'Indirect', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('Future', 'FedFund', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('Future', 'EuroDollar', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('Option', 'Call', now());
insert sec_type (sec_type, sec_sub_type, date_added) values ('Option', 'Put', now());

DROP TABLE IF EXISTS currency;
CREATE TABLE currency (  
	currency_id int(8) NOT NULL AUTO_INCREMENT,  
	currency varchar(3),
	currency_symbol varchar(2),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (currency_id),  
	UNIQUE id (currency_id)
	);

insert currency (currency, currency_symbol, date_added) values ('USD', '$', now());
insert currency (currency, currency_symbol, date_added) values ('CAD', 'C$', now());
insert currency (currency, currency_symbol, date_added) values ('EUR', '€', now());
insert currency (currency, currency_symbol, date_added) values ('GBP', '?', now());
insert currency (currency, currency_symbol, date_added) values ('CHF', 'S', now());
insert currency (currency, currency_symbol, date_added) values ('JPY', '?', now());
insert currency (currency, currency_symbol, date_added) values ('SEK', 'kr', now());


DROP TABLE IF EXISTS exchange;
CREATE TABLE exchange (  
	exchange_id int(8) NOT NULL AUTO_INCREMENT,  
	exchange varchar(12),
	currency int,
	pip_constant numeric (12, 4),
	trade_size numeric (12, 4),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (exchange_id),  
	UNIQUE id (exchange_id)
);

insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('NYSE', (select currency_id from currency where currency='USD'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('SMART', (select currency_id from currency where currency='USD'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('ISLAND', (select currency_id from currency where currency='USD'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('NASDAQ', (select currency_id from currency where currency='USD'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('TSE', (select currency_id from currency where currency='CAD'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('VIRTX', (select currency_id from currency where currency='CHF'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('IBIS', (select currency_id from currency where currency='EUR'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('AMEX', (select currency_id from currency where currency='USD'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('SFB', (select currency_id from currency where currency='SEK'), 0.01, 100, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('IDEAL', (select currency_id from currency where currency='USD'), 0.0001, 1000, now());
insert exchange (exchange, currency, pip_constant, trade_size, date_added) values ('IDEALPRO', (select currency_id from currency where currency='USD'), 0.0001, 1000, now());


DROP TABLE IF EXISTS security;
CREATE TABLE security (  
	security_id int(8) NOT NULL AUTO_INCREMENT,  
	underlyer int,  
	sec_type int NOT NULL,  
	exchange int,
	primary_exchange int,
	ticker varchar(8),
	cusip varchar(10),
	bloomberg varchar(12),
	pip_constant numeric (12, 4),
	trade_size numeric (12, 4),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (security_id),  
	UNIQUE id (security_id)
	);

insert security (sec_type, exchange, primary_exchange, ticker, pip_constant, trade_size, date_added) values (
	(select sec_type_id from sec_type where sec_sub_type='Adr'), 
	(select exchange_id from exchange where exchange='NYSE'), 
	(select exchange_id from exchange where exchange='SMART'), 
	'AUY', 
	null, null, now());
insert security (sec_type, exchange, primary_exchange, ticker, pip_constant, trade_size, date_added) values (
	(select sec_type_id from sec_type where sec_sub_type='Ord'), 
	(select exchange_id from exchange where exchange='TSE'), 
	(select exchange_id from exchange where exchange='SMART'), 
	'YRI', 
	null, null, now());
insert security (sec_type, exchange, primary_exchange, ticker, pip_constant, trade_size, date_added) values (
	(select sec_type_id from sec_type where sec_sub_type='Direct'), 
	(select exchange_id from exchange where exchange='SMART'), 
	(select exchange_id from exchange where exchange='SMART'), 
	'USD.CAD', 
	null, null, now());

DROP TABLE IF EXISTS tick_type;
CREATE TABLE tick_type (  
	tick_type_id int(8) NOT NULL AUTO_INCREMENT,  
	tick_type varchar(12),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (tick_type_id),  
	UNIQUE id (tick_type_id)
	);

insert tick_type (tick_type, date_added) values ('Bid', now());
insert tick_type (tick_type, date_added) values ('Ask', now());
insert tick_type (tick_type, date_added) values ('Last', now());
insert tick_type (tick_type, date_added) values ('High', now());
insert tick_type (tick_type, date_added) values ('Low', now());
insert tick_type (tick_type, date_added) values ('Open', now());
insert tick_type (tick_type, date_added) values ('Close', now());

DROP TABLE IF EXISTS tick_verbose;
CREATE TABLE tick_verbose (  
	tick_verbose_id int(8) NOT NULL AUTO_INCREMENT,  
	security_id int(8),
	exchange_id int(8),
	tick_type_id int(8),
	tick_time datetime,
	tick_micro int(8),
	tick numeric (12, 4),
	size int(8),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (tick_verbose_id),  
	UNIQUE id (tick_verbose_id)
	);
    
DROP TABLE IF EXISTS sec_daily;
CREATE TABLE sec_daily (  
	sec_daily_id int(8) NOT NULL AUTO_INCREMENT,  
	security_id int(8),
	exchange_id int(8),
    daily_time datetime,
	open_px numeric (12, 4),
	high_px numeric (12, 4),
	low_px numeric (12, 4),
	close_px numeric (12, 4),
	volume int,
	adj_close numeric (12, 4),
	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (sec_daily_id),  
	UNIQUE id (sec_daily_id)
	);    
    
DROP TABLE IF EXISTS sec_fundamental;
CREATE TABLE sec_fundamental (  
	sec_fundamental_id int(8) NOT NULL AUTO_INCREMENT,  
	security_id int(8),
	exchange_id int(8),
    fundamental_time datetime,

	-- Stats
	OneyrTargetPrice numeric (12, 4) NULL,
	MarketCapitalization varchar(12) NULL,
	AverageDailyVolume numeric (12, 4) NULL,
    
	-- MAs
	FiftydayMovingAverage numeric (12, 4) NULL,
	ChangeFromFiftydayMovingAverage numeric (12, 4) NULL,
	PercentChangeFromFiftydayMovingAverage numeric (12, 4) NULL,
	TwoHundreddayMovingAverage numeric (12, 4) NULL,
	ChangeFromTwoHundreddayMovingAverage numeric (12, 4) NULL,
	PercentChangeFromTwoHundreddayMovingAverage numeric (12, 4) NULL,

	-- Earnings
	EarningsShare numeric (12, 4) NULL,
	EPSEstimateCurrentYear numeric (12, 4) NULL,
	EPSEstimateNextQuarter numeric (12, 4) NULL,
	EPSEstimateNextYear numeric (12, 4) NULL,
	PriceEPSEstimateCurrentYear numeric (12, 4) NULL,
	PriceEPSEstimateNextYear numeric (12, 4) NULL,

	-- Dividends
	DividendPayDate varchar(12) NULL,
	DividendYield numeric (12, 4) NULL,
	ExDividendDate varchar(12) NULL,
	DividendShare numeric (12, 4) NULL,
    
    -- Ratios
	BookValue numeric (12, 4) NULL,
	PriceSales numeric (12, 4) NULL,
	PERatio numeric (12, 4) NULL,
	PEGRatio numeric (12, 4) NULL,
	ShortRatio numeric (12, 4) NULL,

	date_added datetime,
	date_modified datetime,
	PRIMARY KEY (sec_fundamental_id),  
	UNIQUE id (sec_fundamental_id)
	);       

'''    
SET SQL_SAFE_UPDATES = 0;
delete from volarb.sec_daily where TRUE;
SET SQL_SAFE_UPDATES = 1;    
'''


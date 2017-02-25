# AWQL - The AWQL Command-Line Tool

[![GoDoc](https://godoc.org/github.com/rvflash/awql?status.svg)](https://godoc.org/github.com/rvflash/awql)
[![Build Status](https://img.shields.io/travis/rvflash/awql.svg)](https://travis-ci.org/rvflash/awql)
[![Go Report Card](https://goreportcard.com/badge/github.com/rvflash/awql)](https://goreportcard.com/report/github.com/rvflash/awql)


Allows to request Google Adwords API reports with AWQL language.
It is a simple SQL shell with input line editing capabilities. It supports interactive and non-interactive use.
When used interactively, query results are presented in an ASCII-table format.
When used non-interactively, the result is presented in comma-separated format. The output format or many other tricks can be changed using command options.


## Installation

In order to improve the portability of this tool, since the v1.0.0, Awql is no longer developed in Bash and Awk but entirely in Go.

`awql` requires Go 1.7.1 or later.

```bash
$ go get -u github.com/rvflash/awql
```


### Usage

```bash
$ awql -i "123-456-7890"
Welcome to the AWQL monitor. Commands end with ; or \G.
Your AWQL connection implicitly excludes zero impressions.
Adwords API version: v201609

Reading table information for completion of table and column names.
You can turn off this feature to get a quicker startup with -A

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

awql> SELECT CampaignName, Clicks, Impressions, Cost, Amount, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 5;
+--------------+---------+--------------+------------+-----------+--------------------+
| Campaign     | Clicks  | Impressions  | Cost       | Budget    | Tracking template  |
+--------------+---------+--------------+------------+-----------+--------------------+
| Campaign #1  | 526     | 42006        | 456020000  | 33000000  | --                 |
| Campaign #2  | 0       | 0            | 0          | 33000000  | --                 |
| Campaign #3  | 0       | 0            | 0          | 33000000  | --                 |
| Campaign #4  | 4       | 310          | 1210000    | 1000000   | --                 |
| Campaign #5  | 196     | 13168        | 242870000  | 26000000  | --                 |
+--------------+---------+--------------+------------+-----------+--------------------+
5 rows in set (0.322 sec)
```
 
 
## Features

* Auto-refreshed the Google access token with the Google OAuth2 services.
* When used interactively, adds the management of historic of queries with arrow keys.
* Adds to AWQL grammar for requesting Adwords reports the following SQL clauses to `SELECT` statement: `LIMIT`, `GROUP BY` and `ORDER BY`.
* Also offers the SQL methods `DESC [FULL]`, `SHOW [FULL] TABLES [LIKE|WITH]` and `CREATE [OR REPLACE] VIEW`.
* Adds management of `\G` modifier to display result vertically (each column on a line)
* Also adds the aggregate functions: `AVG`, `COUNT`, `MAX`, `MIN`, `SUM` and `DISTINCT` keyword.
* `*` can be used as shorthand to select all columns from all views
* Caching data in order to don't request Google Adwords services with queries already fetch in the day. This feature can be enable with option `-c`. 
* By default, all calls implicitly excludes zero impressions. This behavior can be changed with the option `-z`.


## SQL methods adding to AWQL grammar


#### DESC [FULL] table_name [column_name]

```bash
$ awql> desc CAMPAIGN_SHARED_SET_REPORT;
+------------------------+----------------+-----+---------------------------+
| Field                  | Type           | Key | Supports_Zero_Impressions |
+------------------------+----------------+-----+---------------------------+
| AccountDescriptiveName | String         |     | YES                       |
| CampaignId             | Long           |     | YES                       |
| CampaignName           | String         |     | YES                       |
| CampaignStatus         | CampaignStatus |     | YES                       |
| ExternalCustomerId     | Long           |     | YES                       |
| SharedSetName          | String         | PRI | YES                       |
| SharedSetType          | SharedSetType  |     | YES                       |
| Status                 | Status         |     | YES                       |
+------------------------+----------------+-----+---------------------------+
8 rows in set (0.000 sec)
```


#### SELECT ... \G

```bash
$ awql> SELECT CampaignName, Clicks, Impressions, Cost, Amount, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 1\G
**************************** 1. row ****************************
       CampaignName: Campagne Shopping
             Clicks: 276526
        Impressions: 10293554
               Cost: 179673040000
             Amount: 500000000
TrackingUrlTemplate:  --
1 row in set (1.109 sec)
```

The FULL modifier is supported such that DESC FULL displays two more columns with enum values and uncompatibles fields list.

```bash
$ awql> desc full CAMPAIGN_PERFORMANCE_REPORT EnhancedCpcEnabled;
+--------------------+------+-----+---------------------------+-------------+---------------------+
| Field              | Type | Key | Supports_Zero_Impressions | Enum        | Not_compatible_with |
+--------------------+------+-----+---------------------------+-------------+---------------------+
| EnhancedCpcEnabled | Enum |     | YES                       | TRUE, FALSE |                     |
+--------------------+------+-----+---------------------------+-------------+---------------------+
1 row in set (0.000 sec)
```


#### SHOW [FULL] TABLES [LIKE 'pattern']

```bash
$ awql> SHOW TABLES LIKE "CAMPAIGN%";
+-------------------------------------------------+
| Tables_in_v201609                               |
+-------------------------------------------------+
| CAMPAIGN_AD_SCHEDULE_TARGET_REPORT              |
| CAMPAIGN_LOCATION_TARGET_REPORT                 |
| CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT   |
| CAMPAIGN_NEGATIVE_LOCATIONS_REPORT              |
| CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT |
| CAMPAIGN_PERFORMANCE_REPORT                     |
| CAMPAIGN_PLATFORM_TARGET_REPORT                 |
| CAMPAIGN_SHARED_SET_REPORT                      |
+-------------------------------------------------+
8 rows in set (0.001 sec)
```

The FULL modifier is supported such that SHOW FULL TABLES displays a second output column with the type of table.

```bash
$ awql> show full tables like "ADGROUP%";
+----------------------------+------------+
| Tables_in_v201609          | Table_type |
+----------------------------+------------+
| ADGROUP_PERFORMANCE_REPORT | BASE TABLE |
+----------------------------+------------+
1 row in set (0.000 sec)
```


#### SHOW TABLES [WITH 'pattern']

```bash
$ awql> show full tables with Url;
+--------------------------+------------+
| Tables_in_v201609        | Table_type |
+--------------------------+------------+
| KEYWORDLESS_QUERY_REPORT | BASE TABLE |
| URL_PERFORMANCE_REPORT   | BASE TABLE |
+--------------------------+------------+
2 rows in set (0.000 sec)
```


#### SELECT ... LIMIT [offset,] row_count

```bash
$ awql> SELECT CampaignName, Clicks, Impressions, Cost, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 3;
+-------------+---------+--------------+------------+--------------------+
| Campaign    | Clicks  | Impressions  | Cost       | Tracking template  |
+-------------+---------+--------------+------------+--------------------+
| Campaign #1 | 12      | 1289         | 9760000    | --                 |
| Campaign #2 | 8       | 1490         | 7010000    | --                 |
| Campaign #3 | 432     | 26469        | 450420000  | --                 |
+-------------+---------+--------------+------------+--------------------+
3 rows in set (0.01 sec)
```


#### SELECT ... ORDER BY column_name [ASC | DESC]

```bash
$ awql> SELECT CampaignName, Clicks, Impressions FROM CAMPAIGN_PERFORMANCE_REPORT ORDER BY Impressions DESC;
+--------------+---------+--------------+
| Campaign     | Clicks  | Impressions  |
+--------------+---------+--------------+
| Campaign #12 | 526     | 42006        |
| Campaign #3  | 432     | 26469        |
| Campaign #5  | 196     | 13168        |
| Campaign #10 | 145     | 8646         |
| Campaign #2  | 8       | 1490         |
| Campaign #1  | 12      | 1289         |
| Campaign #4  | 4       | 310          |
| Campaign #6  | 3       | 295          |
| Campaign #9  | 3       | 259          |
| Campaign #13 | 4       | 248          |
| Campaign #11 | 10      | 237          |
| Campaign #7  | 0       | 9            |
| Campaign #14 | 0       | 9            |
| Campaign #8  | 0       | 2            |
+--------------+---------+--------------+
14 rows in set (0.801 sec)
```
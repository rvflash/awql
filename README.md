# AWQL - The AWQL Command-Line Tool

Allows to request Google Adwords API reports with AWQL language.
It is a simple SQL shell with input line editing capabilities. It supports interactive and non-interactive use.
When used interactively, query results are presented in an ASCII-table format.
When used non-interactively, the result is presented in comma-separated format. The output format or many other tricks can be changed using command options.

## Installation

In order to improve the portability of this tool, since the v2.0.0, Awql is no longer developed with Bash and Awk but entirely with Go.

'awql' requires Go 1.7.1 or later.

```bash
~ $ go get -u github.com/rvflash/awql
```


### Usage

```bash
~ $ awql -i "123-456-7890"
~ Welcome to the AWQL monitor. Commands end with ; or \g.
~ Your AWQL connection implicitly excludes zero impressions.
~ Adwords API version: v201609
~ 
~ Reading table information for completion of table and column names.
~ You can turn off this feature to get a quicker startup with -A
~ 
~ Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
~ 
~ awql> SELECT CampaignName, Clicks, Impressions, Cost, Amount, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 5;
~ +--------------+---------+--------------+------------+-----------+--------------------+
~ | Campaign     | Clicks  | Impressions  | Cost       | Budget    | Tracking template  |
~ +--------------+---------+--------------+------------+-----------+--------------------+
~ | @3 #sp       | 526     | 42006        | 456020000  | 33000000  |                    |
~ | Sports #1    | 0       | 0            | 0          | 33000000  |                    |
~ | Lingerie #1  | 0       | 0            | 0          | 33000000  |                    |
~ | Enfant #1    | 4       | 310          | 1210000    | 1000000   |                    |
~ | Mode #1      | 196     | 13168        | 242870000  | 26000000  |                    |
~ +--------------+---------+--------------+------------+-----------+--------------------+
~ 5 rows in set (0.322 sec)
```
 
 
## Features

* Auto-refreshed the Google access token with the Google oauth2 services.
* When used interactively, adds the management of historic of queries with arrow keys.
* Adds to Awql grammar for requesting Adwords reports the following SQL clauses to `SELECT` statement: `LIMIT`, `GROUP BY` and `ORDER BY`.
* Also offers the SQL methods `DESC [FULL]`, `SHOW [FULL] TABLES [LIKE|WITH]` and `CREATE [OR REPLACE] VIEW`.
* Add management of `\G` modifier to display result vertically (each column on a line)
* The view offers possibility to filter the AWQL report tables to create your own report, with only the columns that interest you.
* `*` can be used as shorthand to select all columns from all views
* Caching datas in order to do not request Google Adwords services with queries already fetch in the day. This feature can be enable with option `-c`. 
* By default, all calls implicitly excludes zero impressions. This behavior can be changed with the option `-z`.


## SQL methods adding to AWQL grammar


#### CREATE [OR REPLACE] VIEW view_name [(column_list)] AS select_statement

```bash
~ $ awql -i "123-456-7890" -e "CREATE VIEW CAMPAIGN_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks, Conversions, Cost, AverageCpc FROM CAMPAIGN_PERFORMANCE_REPORT;"
```


#### SELECT * FROM view_name

Only works on view. Adwords tables are not designed for that. Too much columns, fields incompatibles between them.

```bash
~ $ awql -c -v -i "123-456-7890" -e "SELECT * FROM CAMPAIGN_REPORT LIMIT 5;
+--------------+--------------------+-----------------+--------------+---------+--------------+--------------+-----------+
| Campaign ID  | Campaign           | Campaign state  | Impressions  | Clicks  | Conversions  | Cost         | Avg. CPC  |
+--------------+--------------------+-----------------+--------------+---------+--------------+--------------+-----------+
| 296640682    | @2 #sp             | paused          | 297897       | 8962    | 455.0        | 5786650000   | 645687    |
| 296747482    | @3 #sp             | paused          | 511010       | 13150   | 403.0        | 9464370000   | 719724    |
| 355842362    | Sports #1          | enabled         | 1768447      | 48403   | 1,791.0      | 26885290000  | 555447    |
| 355843562    | Bijoux #1          | enabled         | 21600        | 442     | 35.0         | 195850000    | 443100    |
| 355844402    | Audio et Vidéo #1  | enabled         | 91901        | 2351    | 40.0         | 1001070000   | 425806    |
+--------------+--------------------+-----------------+--------------+---------+--------------+--------------+-----------+
5 rows in set (0.00 sec) @cached
```


#### DESC [FULL] table_name [column_name]

```bash
~ $ awql -i "123-456-7890" -e "DESC CREATIVE_CONVERSION_REPORT;"
+--------------------------+---------------------------------------------------------------------------------------+------+
| Field                    | Type                                                                                  | Key  |
+--------------------------+---------------------------------------------------------------------------------------+------+
| AccountCurrencyCode      | String                                                                                |      |
| AccountDescriptiveName   | String                                                                                |      |
| AccountTimeZoneId        | String                                                                                |      |
| AdGroupId                | Long                                                                                  |      |
| AdGroupName              | String                                                                                |      |
| AdGroupStatus            | AdGroupStatus (UNKNOWN;ENABLED;PAUSED;REMOVED)                                        |      |
| AdNetworkType1           | AdNetworkType1 (UNKNOWN;SEARCH;CONTENT;YOUTUBE_SEARCH;YOUTUBE_WATCH)                  | MUL  |
| AdNetworkType2           | AdNetworkType2 (UNKNOWN;SEARCH;SEARCH_PARTNERS;CONTENT;YOUTUBE_SEARCH;YOUTUBE_WATCH)  | MUL  |
| CampaignId               | Long                                                                                  |      |
| CampaignName             | String                                                                                |      |
| CampaignStatus           | CampaignStatus (UNKNOWN;ENABLED;PAUSED;REMOVED)                                       |      |
| ClickConversionRate      | Double                                                                                |      |
| ConversionTrackerId      | Long                                                                                  | MUL  |
| ConvertedClicks          | Long                                                                                  |      |
| CreativeId               | Long                                                                                  |      |
| CriteriaParameters       | String                                                                                |      |
| CriteriaTypeName         | String                                                                                |      |
| CriterionId              | Long                                                                                  |      |
| CustomerDescriptiveName  | String                                                                                |      |
| Date                     | Date                                                                                  | MUL  |
| DayOfWeek                | DayOfWeek (MONDAY;TUESDAY;WEDNESDAY;THURSDAY;FRIDAY;SATURDAY;SUNDAY)                  | MUL  |
| ExternalCustomerId       | Long                                                                                  |      |
| Impressions              | Long                                                                                  |      |
| Month                    | String                                                                                | MUL  |
| PrimaryCompanyName       | String                                                                                |      |
| Quarter                  | String                                                                                | MUL  |
| Week                     | String                                                                                | MUL  |
| Year                     | Integer                                                                               | MUL  |
+--------------------------+---------------------------------------------------------------------------------------+------+
28 rows in set (0.01 sec)
```

The FULL modifier is supported such that DESC FULL displays a fourth output column with uncompatibles fields list.

```bash
awql -i "123-345-1234" -e 'DESC FULL SEARCH_QUERY_PERFORMANCE_REPORT VideoViews;'
+-------------+-------+------+----------------------------------------------------------------+
| Field       | Type  | Key  | Not_compatibles                                                |
+-------------+-------+------+----------------------------------------------------------------+
| VideoViews  | Long  |      | ConversionCategoryName ConversionTrackerId ConversionTypeName  |
+-------------+-------+------+----------------------------------------------------------------+
1 row in set (0.01 sec)
```


#### SHOW [FULL] TABLES [LIKE 'pattern']

```bash
~ $ awql -i "123-456-7890" -e 'SHOW TABLES LIKE "CAMPAIGN%";'
+--------------------------------------------------+
| Tables_in_v201509 (CAMPAIGN%)                    |
+--------------------------------------------------+
| CAMPAIGN_AD_SCHEDULE_TARGET_REPORT               |
| CAMPAIGN_LOCATION_TARGET_REPORT                  |
| CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT    |
| CAMPAIGN_NEGATIVE_LOCATIONS_REPORT               |
| CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT  |
| CAMPAIGN_PERFORMANCE_REPORT                      |
| CAMPAIGN_PLATFORM_TARGET_REPORT                  |
| CAMPAIGN_SHARED_SET_REPORT                       |
+--------------------------------------------------+
8 rows in set (0.01 sec)
```

The FULL modifier is supported such that SHOW FULL TABLES displays a second output column with the type of table.
Values for the second column are SINGLE_ATTRIBUTION, MULTIPLE_ATTRIBUTION, STRUCTURE, EXTENSIONS, ANALYTICS or SHOPPING. 

* SINGLE_ATTRIBUTION   : With single attribution, only one of the triggering criteria (e.g., keyword, placement, audience, etc.) will be recorded for a given impression. The Criteria and Keyword reports follow this model. Each impression is counted exactly once (under one criterion).
* MULTIPLE_ATTRIBUTION : With multiple attribution, up to one criterion in each dimension that triggered the impression will have the impression recorded for it. For example, the Display Topic and Placements reports follow this model. As opposed to single attribution, multiple attribution reports should **NOT** be aggregated together, since this may double count impressions and clicks.
* STRUCTURE            : Since these reports do not include performance statistics, you cannot include a `DURING` clause in your AWQL query or use a custom date range in your `ReportDefinition`.
* EXTENSIONS           : Reports dedicated to ad extensions
* ANALYTICS            : The reports below include Google Analytics metrics such as `AveragePageviews`, `BounceRate`, `AverageTimeOnSite`, and `PercentNewVisitors`.
* SHOPPING             : Tables dedicated to shopping campaigns

```bash
~ $ awql -i "123-456-7890" -e 'SHOW FULL TABLES LIKE "CAMPAIGN%";'
+--------------------------------------------------+-----------------------+
| Tables_in_v201509 (CAMPAIGN%)                    | Table_type            |
+--------------------------------------------------+-----------------------+
| CAMPAIGN_AD_SCHEDULE_TARGET_REPORT               |                       |
| CAMPAIGN_LOCATION_TARGET_REPORT                  | MULTIPLE_ATTRIBUTION  |
| CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT    | STRUCTURE             |
| CAMPAIGN_NEGATIVE_LOCATIONS_REPORT               | STRUCTURE             |
| CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT  | STRUCTURE             |
| CAMPAIGN_PERFORMANCE_REPORT                      | ANALYTICS             |
| CAMPAIGN_PLATFORM_TARGET_REPORT                  | MULTIPLE_ATTRIBUTION  |
| CAMPAIGN_SHARED_SET_REPORT                       |                       |
+--------------------------------------------------+-----------------------+
8 rows in set (0.01 sec)
```


#### SHOW TABLES [WITH 'pattern']

```bash
~ $ awql -i "123-456-7890" -e "SHOW TABLES WITH 'ViewThroughConversions';"
+------------------------------------------------+
| Tables_in_v201509_with_ViewThroughConversions  |
+------------------------------------------------+
| ACCOUNT_PERFORMANCE_REPORT                     |
| ADGROUP_PERFORMANCE_REPORT                     |
| AD_PERFORMANCE_REPORT                          |
| AGE_RANGE_PERFORMANCE_REPORT                   |
| AUDIENCE_PERFORMANCE_REPORT                    |
| AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT        |
| BID_GOAL_PERFORMANCE_REPORT                    |
| BUDGET_PERFORMANCE_REPORT                      |
| CAMPAIGN_AD_SCHEDULE_TARGET_REPORT             |
| CAMPAIGN_LOCATION_TARGET_REPORT                |
| CAMPAIGN_PERFORMANCE_REPORT                    |
| CAMPAIGN_PLATFORM_TARGET_REPORT                |
| CRITERIA_PERFORMANCE_REPORT                    |
| DESTINATION_URL_REPORT                         |
| DISPLAY_KEYWORD_PERFORMANCE_REPORT             |
| DISPLAY_TOPICS_PERFORMANCE_REPORT              |
| GENDER_PERFORMANCE_REPORT                      |
| GEO_PERFORMANCE_REPORT                         |
| KEYWORDS_PERFORMANCE_REPORT                    |
| PLACEHOLDER_REPORT                             |
| PLACEMENT_PERFORMANCE_REPORT                   |
| SEARCH_QUERY_PERFORMANCE_REPORT                |
| URL_PERFORMANCE_REPORT                         |
| USER_AD_DISTANCE_REPORT                        |
+------------------------------------------------+
24 rows in set (0.01 sec)
```


#### SELECT ... LIMIT [offset,] row_count

```bash
~ $ awql -i "123-456-7890" -e "SELECT CampaignName, Clicks, Impressions, Cost, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 3"
+-----------+---------+--------------+------------+--------------------+
| Campaign  | Clicks  | Impressions  | Cost       | Tracking template  |
+-----------+---------+--------------+------------+--------------------+
| @0 #sp    | 12      | 1289         | 9760000    |                    |
| @1 #sp    | 8       | 1490         | 7010000    |                    |
| @2 #sp    | 432     | 26469        | 450420000  |                    |
+-----------+---------+--------------+------------+--------------------+
3 rows in set (0.01 sec)
```


#### SELECT ... ORDER BY column_name [ASC | DESC]

```bash
~ $ awql -i "123-456-7890" -e "SELECT CampaignName, Clicks, Impressions FROM CAMPAIGN_PERFORMANCE_REPORT ORDER BY Impressions DESC"
+--------------+---------+--------------+
| Campaign     | Clicks  | Impressions  |
+--------------+---------+--------------+
| @3 #sp       | 526     | 42006        |
| @2 #sp       | 432     | 26469        |
| Mode #1      | 196     | 13168        |
| Mode #1      | 145     | 8646         |
| @1 #sp       | 8       | 1490         |
| @0 #sp       | 12      | 1289         |
| Enfant #1    | 4       | 310          |
| Mode #1      | 3       | 295          |
| Sports #1    | 3       | 259          |
| Sports #1    | 4       | 248          |
| Enfant #1    | 10      | 237          |
| Sports #1    | 0       | 9            |
| Enfant #1    | 0       | 9            |
| Enfant #1    | 0       | 2            |
| Bijoux #1    | 0       | 2            |
| Sports #1    | 0       | 0            |
| Mode #2      | 0       | 0            |
| Mode #1      | 0       | 0            |
| Maison #1    | 0       | 0            |
| Lingerie #1  | 0       | 0            |
| Lingerie #1  | 0       | 0            |
| Lingerie #1  | 0       | 0            |
| Lingerie #1  | 0       | 0            |
+--------------+---------+--------------+
23 rows in set (0.01 sec)
```


#### SELECT ... \G

```bash
~ $ awql -i "123-456-7890" -e "SELECT CampaignName, Clicks, Impressions, Cost, Amount, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 1\G" -c
*************************** 1. row ***************************
         Campaign: @0 #sp
           Clicks: 12
      Impressions: 1289
             Cost: 9760000
           Budget: 33000000
Tracking template:
1 row in set (0.01 sec)
```
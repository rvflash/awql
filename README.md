# AWQL

Bash command line tool to request Google Adwords API Reports with AWQL language and print results like mysql command line tool.
 
## Features

* Auto-refreshed the Google access token. 2 ways for this, the classic with the Google oauth2 services and the second, by calling a web service of your choice
* Save results in CSV files.
* In prompt mode, add management of historic of queries with arrow keys
* Caching datas in order to do not request Google Adwords services with queries already fetch in the day. This feature can be enable with option `-c`. 
* Add following SQL methods to AWQL grammar for reports: `LIMIT` and `ORDER BY` in `SELECT` queries, `DESC [FULL]`, `SHOW [FULL] TABLES [LIKE|WITH]` and `CREATE [OR REPLACE] VIEW`.
* Add management of `\G` modifier to display result vertically (each column on a line)
* The view offers possibility to filter the AWQL report tables to create your own report, with only the columns that interest you.
* `*` can be used as shorthand to select all columns from all views

SQL methods adding to AWQL grammar in detail:

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

## Quick start

Clone this repository in the folder of your choice.

### Set up credentials

First, you need to set up the default configuration to use to connect to Google Adwords and create awql command.
Run `./makefile.sh` in awql folder and follow the instruction.

Example with Google as token provider:
```bash
~ $ ./makefile.sh
Welcome to the process to install Awql, a Bash command line tools to request Google Adwords Reports API.
Add awql as bash alias -------------------------------------- OK
Your Google developer token: dEve1op3er7okeN
Use Google to get access tokens (Y/N)? Y
Your Google client ID: 123456789-Aw91.apps.googleusercontent.com
Your Google client secret: C13nt5e0r3t
Your Google refresh token: 1/n-R3fr35h70k3n
Use Google as token provider -------------------------------- OK
Installation successfull. Open a new terminal or reload your bash environment. Enjoy!
```

### Usage

```bash
~ $ usage: awql -i adwordsId [-T accessToken] [-D developerToken] [-e query] [-V apiVersion] [-b] [-c] [-d] [-v] [-A]
-i for Google Adwords account ID
-T for Google Adwords access token
-D for Google developer token
-e for AWQL query, if not set here, a prompt will be launch
-V Google API version, by default 'v201607'
-b batch mode to print results using comma as the column separator
-c used to enable cache
-d used to enable debug mode, print real query as status line
-v used to print more information
-A Disable automatic rehashing. This option is on by default, which enables table and column name completion
```

### And, make your first call

```bash
~ $ awql -i "123-456-7890" -e "SELECT CampaignName, Clicks, Impressions, Cost, Amount, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 5"
+--------------+---------+--------------+------------+-----------+--------------------+
| Campaign     | Clicks  | Impressions  | Cost       | Budget    | Tracking template  |
+--------------+---------+--------------+------------+-----------+--------------------+
| @3 #sp       | 526     | 42006        | 456020000  | 33000000  |                    |
| Sports #1    | 0       | 0            | 0          | 33000000  |                    |
| Lingerie #1  | 0       | 0            | 0          | 33000000  |                    |
| Enfant #1    | 4       | 310          | 1210000    | 1000000   |                    |
| Mode #1      | 196     | 13168        | 242870000  | 26000000  |                    |
+--------------+---------+--------------+------------+-----------+--------------------+
5 rows in set (1,449 sec)
```

### Go further by using your own web service to get a valid access token

This web service must return a JSON response with this format:

```json
{
    "access_token": "ya29.ExaMple",
    "token_type": "Bearer",
    "expire_at": "2015-12-20T00:35:58+01:00"
}
```

Run `./makefile.sh` in order to change default configuration and use this web service.

```bash
~ $ ./makefile.sh
Welcome to the process to install Awql, a Bash command line tools to request Google Adwords Reports API.
Add awql as bash alias -------------------------------------- OK
Your Google developer token: dEve1op3er7okeN
Use Google to get access tokens (Y/N)? N
Url of the web service to use to retrieve a Google access token: http://ws.local:8961/google-token
Use a custom web service as token provider ------------------ OK
Installation successfull. Open a new terminal or reload your bash environment. Enjoy!
```

## Require

Bash 4.3.11+

### On OS X

We need a modern bash and gawk.

```bash
# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# brew install bash
# brew install gawk
```

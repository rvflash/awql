# AWQL

Bash command line tool to request Google Adwords API Reports with AWQL language and print results like mysql command line tool.
 
## Features

* Save results in CSV files.
* Caching datas in order to do not request Google Adwords services with queries already fetch in the day. This feature can be enable with option `-c`. 
* Add following SQL methods to AWQL grammar: `LIMIT` and `ORDER BY` in `SELECT` queries, `DESC` and `SHOW TABLES [LIKE|WITH]`.

SQL methods adding to AWQL grammar in detail:

### DESC TABLE_NAME [COLUMN_NAME]

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
````

### SHOW [FULL] TABLES [LIKE 'pattern']

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
````

### SHOW TABLES [WITH 'pattern']

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
````

### SELECT ... LIMIT [offset,] row_count

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
````

### SELECT ... ORDER BY col_name [ASC | DESC]

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
````

## Quick start

### Set up credentials

First, you need to set up your configuration file named `auth.yaml` properly.
See `auth-sample.yaml` as example, this file will look like this:

```yaml
ACCESS_TOKEN    : ya29.SaMple
DEVELOPER_TOKEN : dEve1op3er7okeN
TOKEN_TYPE      : Bearer
````

### Make your first call

Usage: ${SCRIPT} -i adwordsid [-a authfilepath] [-f awqlfilename] [-e query] [-c] [-v]
* -i for Adwords account ID
* -a for Yaml authorization file path with access and developper tokens
* -f for the filepath to save raw AWQL response
* -e for AWQL query, if not set here, a prompt will be launch
* -c used to enable cache
* -v used to print more informations

```bash
./awql.sh -i "123-456-7890" -e "SELECT CampaignName, Clicks, Impressions, Cost, Amount, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 5"
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
````
# Termtables, bash ASCII Table Generator

Awk scripts to display a CSV file in a shell terminal with readable columns and lines, like with Mysql command line.
Also offers methods to filter or aggregate the CSV file by line or column, count data inside and sum the column values.

In default display mode, all columns are on one line. You can use the first line as header or/and the last as footer.
With the vertical mode, each column has it own line. All both modes can deal with lines with comma inside quotes.


## Basic Usage 

With the following CSV file name `sample.csv` as source.

```csv
Day,Campaign ID,Campaign,Clicks,Impressions,Cost,Mobile Url,Campaign state,Tracking template
2015-10-01,1234567890,@1 #sp,11,297,4420000,,paused,
2015-10-20,1234567890,@1 #sp,17,1242,17170000,,paused,https://github.com/rvflash
2015-10-22,123,@3 #sp,10,854,13290000,,paused,
2015-10-24,1234567890,@1 #sp,4,547,4740000,,paused,
2015-10-26,123456,"@2 ,#sp",4,577,1310000,,paused,
```


#### Print a CSV file in the term with first as header

```bash
$ awk -f termTable.awk tests/unit/sample.csv
+------------+-------------+----------+--------+-------------+----------+------------+----------------+----------------------------+
| Day        | Campaign ID | Campaign | Clicks | Impressions | Cost     | Mobile Url | Campaign state | Tracking template          |
+------------+-------------+----------+--------+-------------+----------+------------+----------------+----------------------------+
| 2015-10-01 | 1234567890  | @1 #sp   | 11     | 297         | 4420000  |            | paused         |                            |
| 2015-10-20 | 1234567890  | @1 #sp   | 17     | 1242        | 17170000 |            | paused         | https://github.com/rvflash |
| 2015-10-22 | 123         | @3 #sp   | 10     | 854         | 13290000 |            | paused         |                            |
| 2015-10-24 | 1234567890  | @1 #sp   | 4      | 547         | 4740000  |            | paused         |                            |
| 2015-10-26 | 123456      | @2 ,#sp  | 4      | 577         | 1310000  |            | paused         |                            |
+------------+-------------+----------+--------+-------------+----------+------------+----------------+----------------------------+
```


#### Print it with vertical display mode

```bash
$ awk -v verticalMode=1 -f termTable.awk tests/unit/sample.csv
**************************** 1. row ****************************
              Day: 2015-10-01
      Campaign ID: 1234567890
         Campaign: @1 #sp
           Clicks: 11
      Impressions: 297
             Cost: 4420000
       Mobile Url:
   Campaign state: paused
Tracking template:
**************************** 2. row ****************************
              Day: 2015-10-20
      Campaign ID: 1234567890
         Campaign: @1 #sp
           Clicks: 17
      Impressions: 1242
             Cost: 17170000
       Mobile Url:
   Campaign state: paused
Tracking template: https://github.com/rvflash
**************************** 3. row ****************************
              Day: 2015-10-22
      Campaign ID: 123
         Campaign: @3 #sp
           Clicks: 10
      Impressions: 854
             Cost: 13290000
       Mobile Url:
   Campaign state: paused
Tracking template:
**************************** 4. row ****************************
              Day: 2015-10-24
      Campaign ID: 1234567890
         Campaign: @1 #sp
           Clicks: 4
      Impressions: 547
             Cost: 4740000
       Mobile Url:
   Campaign state: paused
Tracking template:
**************************** 5. row ****************************
              Day: 2015-10-26
      Campaign ID: 123456
         Campaign: @2 ,#sp
           Clicks: 4
      Impressions: 577
             Cost: 1310000
       Mobile Url:
   Campaign state: paused
Tracking template:
```


## Advanced Usage

More options are available for `termTable.awk`, see list below:

* `verticalMode`, enable vertical display table
* `withFooter`, use the last line as footer. Option disabled with verticalMode 
* `withoutHeader`, disable the first line as header. Option disabled with verticalMode
* `addHeader`, line to add as header with column's names separated by comma
* `replaceHeader`, The non-empty values separated by comma overloads the column's names
* `columnSeparator`, character to separate column, default "|"
* `columnBounce`, character to bounce separate line, default "+"
* `columnBreakLine`, character to use as break line, default "-" or "*" in vertical mode
* `lineLabel`, string to use as suffix of the line number in vertical mode


### Replace name of columns at index 1 and 3.

```bash
$ awk -v replaceHeader="Date,,Name" -f termTable.awk tests/unit/sample.csv
+------------+-------------+---------+--------+-------------+----------+------------+----------------+----------------------------+
| Date       | Campaign ID | Name    | Clicks | Impressions | Cost     | Mobile Url | Campaign state | Tracking template          |
+------------+-------------+---------+--------+-------------+----------+------------+----------------+----------------------------+
| 2015-10-01 | 1234567890  | @1 #sp  | 11     | 297         | 4420000  |            | paused         |                            |
| 2015-10-20 | 1234567890  | @1 #sp  | 17     | 1242        | 17170000 |            | paused         | https://github.com/rvflash |
| 2015-10-22 | 123         | @3 #sp  | 10     | 854         | 13290000 |            | paused         |                            |
| 2015-10-24 | 1234567890  | @1 #sp  | 4      | 547         | 4740000  |            | paused         |                            |
| 2015-10-26 | 123456      | @2 ,#sp | 4      | 577         | 1310000  |            | paused         |                            |
+------------+-------------+---------+--------+-------------+----------+------------+----------------+----------------------------+
```


### Limit display to some columns or lines

Exclude columns named Day, Mobile Url, Campaign state and Tracking template.

```bash
$ awk -v columns="2 3 4 5 6" -f limit.awk tests/unit/sample.csv | awk -f termTable.awk
+-------------+----------+--------+-------------+----------+
| Campaign ID | Campaign | Clicks | Impressions | Cost     |
+-------------+----------+--------+-------------+----------+
| 1234567890  | @1 #sp   | 11     | 297         | 4420000  |
| 1234567890  | @1 #sp   | 17     | 1242        | 17170000 |
| 123         | @3 #sp   | 10     | 854         | 13290000 |
| 1234567890  | @1 #sp   | 4      | 547         | 4740000  |
| 123456      | @2 ,#sp  | 4      | 577         | 1310000  |
+-------------+----------+--------+-------------+----------+
```

Available options for `limit.awk`, see list below:

* `withHeader`, use first as header
* `columns`, list of columns by index to display, separated by space
* `rowOffset`, starting offset for rows limit
* `rowCount`, number of line requested in limit


### Aggregate data by columns

Group sample datas by Campaign ID and sum the clicks, impressions and cost.

```bash
$ awk -v columns="2 3 4 5 6" -f limit.awk tests/unit/sample.csv | awk -v groupByColumns="1" -v sumColumns="3 4 5" -v omitHeader=1 -v header="Campaign Id,Name,Sum of clicks, Sum of impression, Sum of cost" -f aggregate.awk | awk -f termTable.awk
+-------------+---------+---------------+-------------------+-------------+
| Campaign Id | Name    | Sum of clicks | Sum of impression | Sum of cost |
+-------------+---------+---------------+-------------------+-------------+
| 1234567890  | @1 #sp  | 32            | 2086              | 26330000    |
| 123456      | @2 ,#sp | 4             | 577               | 1310000     |
| 123         | @3 #sp  | 10            | 854               | 13290000    |
+-------------+---------+---------------+-------------------+-------------+
```

Available options for `aggregate.awk`, see list below:

* `header`, define new header line
* `omitHeader`, use to exclude the first line
* `distinctLine`, aggregate by the entire line
* `avgColumns`, list of columns per index on which to calculate the average, separated by space
* `distinctColumns`, list of columns by index to use in single mode
* `countColumns`, list of columns by index to count, separated by space
* `maxColumns`, list of columns per index where find the max value, separated by space
* `minColumns`, list of columns per index where find the min value, separated by space
* `sumColumns`, list of columns by index to sum, separated by space
* `groupByColumns`, list of columns by index to use to group, separated by space
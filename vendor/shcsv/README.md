# ShCsv 

Bash library to print a CSV file in a shell terminal with readable columns and lines, like with Mysql command line.
Two modes ar now available. The basic, with all columns in one line and the vertical mode, where each column has it line.

```bash
usage: csv.sh -f csvSourceFile [-t csvSaveFile] [-s columnSeparator] [-g] [-q]
-f for CSV source file path
-t for save result in this file path
-s to define column separator, by default: comma
-g for enable vertical mode
-q for does not print result
```

## Examples 

With the following CSV file name `sample.csv` as source.

```csv
Day,Campaign ID,Campaign,Clicks,Impressions,Cost,Mobile Url,Campaign state,Tracking template
2015-10-01,1234567890,@1 #sp,11,297,4420000,,paused,
2015-10-20,1234567890,@2 #sp,17,1242,17170000,,paused,https://github.com/rvflash
2015-10-22,123,@3 #sp,10,854,13290000,,paused,
2015-10-24,1234567890,@4 #sp,4,547,4740000,,paused,
2015-10-26,123456,@5 #sp,4,577,1310000,,paused,
```

### Print a CSV file in the term

```bash
$ ./csv.sh -f "sample.csv"
+-------------+--------------+-----------+---------+--------------+-----------+-------------+-----------------+-----------------------------+
| Day         | Campaign ID  | Campaign  | Clicks  | Impressions  | Cost      | Mobile Url  | Campaign state  | Tracking template           |
+-------------+--------------+-----------+---------+--------------+-----------+-------------+-----------------+-----------------------------+
| 2015-10-01  | 1234567890   | @1 #sp    | 11      | 297          | 4420000   |             | paused          |                             |
| 2015-10-20  | 1234567890   | @2 #sp    | 17      | 1242         | 17170000  |             | paused          | https://github.com/rvflash  |
| 2015-10-22  | 123          | @3 #sp    | 10      | 854          | 13290000  |             | paused          |                             |
| 2015-10-24  | 1234567890   | @4 #sp    | 4       | 547          | 4740000   |             | paused          |                             |
| 2015-10-26  | 123456       | @5 #sp    | 4       | 577          | 1310000   |             | paused          |                             |
+-------------+--------------+-----------+---------+--------------+-----------+-------------+-----------------+-----------------------------+
```

### Save result in an other file, named sample.pcsv and do not display the result

```bash
$ ./csv.sh -f "sample.csv" -t "sample.pcsv" -q
```

### Print it in vertical mode

```bash
./csv.sh -f "sample.csv" -g
*************************** 1. row ***************************
              Day: 2015-10-01
      Campaign ID: 1234567890
         Campaign: @1 #sp
           Clicks: 11
      Impressions: 297
             Cost: 4420000
       Mobile Url:
   Campaign state: paused
Tracking template:
*************************** 2. row ***************************
              Day: 2015-10-20
      Campaign ID: 1234567890
         Campaign: @2 #sp
           Clicks: 17
      Impressions: 1242
             Cost: 17170000
       Mobile Url:
   Campaign state: paused
Tracking template: https://github.com/rvflash
*************************** 3. row ***************************
              Day: 2015-10-22
      Campaign ID: 123
         Campaign: @3 #sp
           Clicks: 10
      Impressions: 854
             Cost: 13290000
       Mobile Url:
   Campaign state: paused
Tracking template:
*************************** 4. row ***************************
              Day: 2015-10-24
      Campaign ID: 1234567890
         Campaign: @4 #sp
           Clicks: 4
      Impressions: 547
             Cost: 4740000
       Mobile Url:
   Campaign state: paused
Tracking template:
*************************** 5. row ***************************
              Day: 2015-10-26
      Campaign ID: 123456
         Campaign: @5 #sp
           Clicks: 4
      Impressions: 577
             Cost: 1310000
       Mobile Url:
   Campaign state: paused
Tracking template:
```
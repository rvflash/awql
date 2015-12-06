# SHCSV 

Bash library to print a CSV file in a Shell terminal with readable columns and lines, like with Mysql command line

Usage: csv.sh -f csvsourcefile [-t csvsavefile] [-s columnseparator] [-q]
* -f for CSV source file
* -t for save result
* -s to define column separator, by default comma
* -q for do not print result

## Examples 

With the following CSV file name sample.csv:

```csv
Day,Campaign ID,Campaign,Clicks,Impressions,Cost,Mobile Url,Campaign state,Tracking template
2015-10-01,1234567890,@3 #sp,11,297,4420000,,paused,
2015-10-20,1234567890,@3 #sp,17,1242,17170000,,paused,https://github.com/rvflash
2015-10-22,123,@3 #sp,10,854,13290000,,paused,
2015-10-24,1234567890,@3 #sp,4,547,4740000,,paused,
2015-10-26,123456,@3 #sp,4,577,1310000,,paused,
2015-10-27,123,@3 #sp,13,656,6880000,,paused,
2015-10-28,123,@3 #sp,6,640,1370000,,paused,
2015-11-01,123456789,@3 #sp,12,729,7500000,,paused,
2015-11-06,123456,@3 #sp,6,544,3070000,,paused,
2015-11-08,123456,@3 #sp,9,984,5470000,,paused,
2015-11-09,123,@3 #sp,9,1007,3820000,,paused,
2015-11-10,123456,@3 #sp,13,555,6980000,,paused,
2015-11-13,123456,@3 #sp,14,1275,18120000,,paused,https://github.com/rvflash
2015-11-15,123456,@3 #sp,14,1302,11910000,,paused,
````

### Print a CSV file in the term

```bash
$ ./csv.sh -f "sample.csv"
+-------------+--------------+-----------+---------+--------------+-----------+-------------+-----------------+-----------------------------+
| Day         | Campaign ID  | Campaign  | Clicks  | Impressions  | Cost      | Mobile Url  | Campaign state  | Tracking template           |
+-------------+--------------+-----------+---------+--------------+-----------+-------------+-----------------+-----------------------------+
| 2015-10-01  | 1234567890   | @3 #sp    | 11      | 297          | 4420000   |             | paused          |                             |
| 2015-10-20  | 1234567890   | @3 #sp    | 17      | 1242         | 17170000  |             | paused          | https://github.com/rvflash  |
| 2015-10-22  | 123          | @3 #sp    | 10      | 854          | 13290000  |             | paused          |                             |
| 2015-10-24  | 1234567890   | @3 #sp    | 4       | 547          | 4740000   |             | paused          |                             |
| 2015-10-26  | 123456       | @3 #sp    | 4       | 577          | 1310000   |             | paused          |                             |
| 2015-10-27  | 123          | @3 #sp    | 13      | 656          | 6880000   |             | paused          |                             |
| 2015-10-28  | 123          | @3 #sp    | 6       | 640          | 1370000   |             | paused          |                             |
| 2015-11-01  | 123456789    | @3 #sp    | 12      | 729          | 7500000   |             | paused          |                             |
| 2015-11-06  | 123456       | @3 #sp    | 6       | 544          | 3070000   |             | paused          |                             |
| 2015-11-08  | 123456       | @3 #sp    | 9       | 984          | 5470000   |             | paused          |                             |
| 2015-11-09  | 123          | @3 #sp    | 9       | 1007         | 3820000   |             | paused          |                             |
| 2015-11-10  | 123456       | @3 #sp    | 13      | 555          | 6980000   |             | paused          |                             |
| 2015-11-13  | 123456       | @3 #sp    | 14      | 1275         | 18120000  |             | paused          | https://github.com/rvflash  |
| 2015-11-15  | 123456       | @3 #sp    | 14      | 1302         | 11910000  |             | paused          |                             |
+-------------+--------------+-----------+---------+--------------+-----------+-------------+-----------------+-----------------------------+
````

### Save result in an other file named sample.pcsv

```bash
$ time ./csv.sh -f "sample.csv" -t "sample.pcsv" -s
````
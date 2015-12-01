# SHCSV 

Bash library to print a CSV file in a Shell terminal with readable columns and lines, like Mysql command line

## Example 

With a CSV file named example.csv with the following content:
```csv
STATUS,AVAILABILITY,NB
ACTIVE,,1
ACTIVE,IN_STOCK,4413
ACTIVE,OUT_OF_STOCK,13
DELETED,,3
DELETED,IN_STOCK,18
````

Print in the terminal:
```bash
$ csvToPrintableArray "/tmp/example.csv"
+---------+--------------+------+
| STATUS  | AVAILABILITY | NB   |
+---------+--------------+------+
| ACTIVE  |              |    1 |
| ACTIVE  | IN_STOCK     | 4413 |
| ACTIVE  | OUT_OF_STOCK |   13 |
| DELETED |              |    3 |
| DELETED | IN_STOCK     |   18 |
+---------+--------------+------+
````
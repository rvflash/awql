# AWQL

Bash command line tools to request Google Adwords Reports API and print results like mysql command line tool

## Example

```bash
./awql.sh -i "123-456-7890" -e "SELECT CampaignName, Clicks, Impressions, Cost, TrackingUrlTemplate FROM CAMPAIGN_PERFORMANCE_REPORT" -v
+---------------+----------+---------------+-------------+--------------------+
| Campaign      | Clicks   | Impressions   | Cost        | Tracking template  |
+---------------+----------+---------------+-------------+--------------------+
| Sports #1     | 0        | 0             | 0           |                    |
| Lingerie #1   | 0        | 0             | 0           |                    |
| Enfant #1     | 4        | 310           | 1210000     |                    |
| Mode #1       | 196      | 13168         | 242870000   |                    |
| Bijoux #1     | 0        | 2             | 0           |                    |
| Maison #1     | 0        | 0             | 0           |                    |
+---------------+----------+---------------+-------------+--------------------+
6 rows in set (0,493 sec)
````
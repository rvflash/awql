# Awql Database Driver

AWQL driver for Go's sql package


## Examples

### Simple Awql query
 
```go
// Ignores errors for the demo.
query := "SELECT ExternalCustomerId, AccountDescriptiveName FROM ACCOUNT_PERFORMANCE_REPORT"
db, _ := sql.Open("awql", "123-456-7890|dEve1op3er7okeN|ya29.Acc3ss-7ok3n")
stmt, _ := db.Query(query)
for stmt.Next() {
    var id int
    var name string
    stmt.Scan(&id, &name)
    fmt.Printf("%v: %v\n", id, name)
    // Output: 1234567890: Rv
}
```
 
### Awql query row with arguments

```go
// Ignores errors for the demo.
var name string
query := "SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT Where CampaignId = ?"
row := db.QueryRow(query, 123456789)
row.Scan(&name)
fmt.Printf("%v\n", name)
// Output: Campaign #19
```

### Advanced sample

```go
// Instantiates a data source name.
dsn := awql.NewDsn("123-456-7890")
dsn.DeveloperToken = "dEve1op3er7okeN"
dsn.ClientId = "1234567890-Aw91.apps.googleusercontent.com"
dsn.ClientSecret = "C13nt5e0r3t"
dsn.RefreshToken = "1/n-R3fr35h70k3n"

// Ignores errors for the demo.
query := "SELECT ConversionTypeName, AllConversions, ConversionValue FROM CRITERIA_PERFORMANCE_REPORT DURING LAST_7_DAYS"
db, _ := sql.Open("awql", dsn.String())
stmt, _ := db.Query(query)
cols, _ := stmt.Columns()
fmt.Printf("%q\n", cols)
// Output: ["Conversion name" "All conv." "Total conv. value"]

// Copy references into the slice
size := len(cols)
vals := make([]string, size)
ints := make([]interface{}, size)
for i := range ints {
    ints[i] = &vals[i]
}
for stmt.Next() {
    stmt.Scan(ints...)
    fmt.Printf("%q\n", vals)
}
// Output:
// ["Transactions (Phone)" "6.0" "362.33"]
// ["Transactions (Web)" "1.0" "89.3"]
```

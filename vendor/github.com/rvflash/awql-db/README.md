# Awql Database

All information about Adwords reports represented as tables or user views. 

## Example
 
 ```go
db := awql_db.NewDb("v201609")
// Ignores the check of error for the test
db.Load()
for _, t := range db.TablesPrefixedBy("VIDEO") {
    fmt.Println(t.SourceName())
}
// Output: VIDEO_PERFORMANCE_REPORT
 ```
# Awql Parser

[![GoDoc](https://godoc.org/github.com/rvflash/awql-parser?status.svg)](https://godoc.org/github.com/rvflash/awql-parser)
[![Build Status](https://img.shields.io/travis/rvflash/awql-parser.svg)](https://travis-ci.org/rvflash/awql-parser)
[![Code Coverage](https://img.shields.io/codecov/c/github/rvflash/awql-parser.svg)](http://codecov.io/github/rvflash/awql-parser?branch=master)
[![Go Report Card](https://goreportcard.com/badge/github.com/rvflash/awql-parser)](https://goreportcard.com/report/github.com/rvflash/awql-parser)


Parser for parsing AWQL SELECT, DESCRIBE, SHOW and CREATE VIEW statements.
 
Only the first statement is supported by Adwords API, the others are proposed by the AWQL command line tool.
 
## Examples
 
### Unknown single statement.

```go
q := `SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT;`
stmt, _ := awql.NewParser(strings.NewReader(q)).ParseRow()
if stmt, ok := stmt.(awql.SelectStmt); ok {
    fmt.Println(stmt.SourceName())
    // Output: CAMPAIGN_PERFORMANCE_REPORT
}
```

### Select statement.

```go
q := `SELECT AdGroupName FROM ADGROUP_PERFORMANCE_REPORT;`
stmt, _ := awql.NewParser(strings.NewReader(q)).ParseSelect()
fmt.Printf("Gets the column named %v from %v.\n", stmt.Columns()[0].Name(), stmt.SourceName())
// Output: Gets the column named AdGroupName from ADGROUP_PERFORMANCE_REPORT.
```
 
### Multiple statements.
 
```go
q := `SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT ORDER BY 1 LIMIT 5\GDESC ADGROUP_PERFORMANCE_REPORT AdGroupName;`
stmts, _ := awql.NewParser(strings.NewReader(q)).Parse()
for _, stmt := range stmts {
    switch stmt.(type) {
    case awql.SelectStmt:
        fmt.Println(stmt.(awql.SelectStmt).OrderList()[0].Name())
    case awql.DescribeStmt:
        fmt.Println(stmt.(awql.DescribeStmt).SourceName())
        fmt.Println(stmt.(awql.DescribeStmt).Columns()[0].Name())
    }
}
// Output:
// CampaignName
// ADGROUP_PERFORMANCE_REPORT
// AdGroupName
```
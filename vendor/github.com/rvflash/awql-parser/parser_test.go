package awqlparse_test

import (
	"fmt"
	"strings"

	awql "github.com/rvflash/awql-parser"
)

// Ensure the parser can parse statements correctly.
func ExampleParser_Parse() {
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
}

// Ensure the parser can parse statements correctly and return only the first.
func ExampleParser_ParseRow() {
	q := `SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT;`
	stmt, _ := awql.NewParser(strings.NewReader(q)).ParseRow()
	if stmt, ok := stmt.(awql.SelectStmt); ok {
		fmt.Println(stmt.SourceName())
		// Output: CAMPAIGN_PERFORMANCE_REPORT
	}
}

// Ensure the parser can parse select statement.
func ExampleParser_ParseSelect() {
	q := `SELECT AdGroupName FROM ADGROUP_PERFORMANCE_REPORT;`
	stmt, _ := awql.NewParser(strings.NewReader(q)).ParseSelect()
	fmt.Printf("Gets the column named %v from %v.\n", stmt.Columns()[0].Name(), stmt.SourceName())
	// Output: Gets the column named AdGroupName from ADGROUP_PERFORMANCE_REPORT.
}

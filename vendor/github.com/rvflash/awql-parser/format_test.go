package awqlparse_test

import (
	"strings"
	"testing"

	awql "github.com/rvflash/awql-parser"
)

func TestSelectStmt_String(t *testing.T) {
	var tests = []struct {
		fq, tq string
	}{
		{
			fq: `DESC FULL CAMPAIGN_PERFORMANCE_REPORT`,
		},
		{
			fq: `DESC CAMPAIGN_PERFORMANCE_REPORT CampaignStatus`,
		},
		{
			fq: `SHOW FULL TABLES`,
		},
		{
			fq: `SHOW FULL TABLES LIKE "%rv"`,
		},
		{
			fq: `SHOW FULL TABLES LIKE "%rv%"`,
		},
		{
			fq: `SHOW FULL TABLES LIKE "rv%"`,
		},
		{
			fq: `SHOW TABLES LIKE "rv"`,
		},
		{
			fq: `SHOW TABLES WITH "rv"`,
		},
		{
			fq: `CREATE VIEW rv AS SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 10`,
		},
		{
			fq: `CREATE VIEW rv (Name, Cost) AS SELECT CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT DURING TODAY`,
		},
		{
			fq: `CREATE OR REPLACE VIEW rv AS SELECT CampaignId, Cost FROM CAMPAIGN_PERFORMANCE_REPORT DURING TODAY`,
		},
		{
			fq: `SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT`,
		},
		{
			fq: `SELECT SUM(Cost) AS c FROM CAMPAIGN_PERFORMANCE_REPORT WHERE CampaignStatus = "ENABLED"`,
			tq: `SELECT Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE CampaignStatus = "ENABLED"`,
		},
		{
			fq: `SELECT CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT GROUP BY 1 ORDER BY 2 DESC`,
			tq: `SELECT CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT`,
		},
		{
			fq: `SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT DURING 20161224,20161225 LIMIT 10`,
			tq: `SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT DURING 20161224,20161225`,
		},
	}

	for i, qt := range tests {
		stmt, err := awql.NewParser(strings.NewReader(qt.fq)).ParseRow()
		if err != nil {
			t.Fatalf("%d. Expected no error with '%v', received %v", i, qt.fq, err)
		}
		// Use original query as expected query.
		if qt.tq == "" {
			qt.tq = qt.fq
		}
		// Checks the legacy stringer.
		if sStmt, ok := stmt.(awql.SelectStmt); ok {
			if q := sStmt.LegacyString(); q != qt.tq {
				t.Errorf("%d. Expected the legacy query '%v' with '%s', received '%v'", i, qt.tq, qt.fq, q)
			}
		}
		// Checks the default stringer.
		if q := stmt.String(); q != qt.fq {
			t.Errorf("%d. Expected the query '%v' with '%s', received '%v'", i, qt.fq, qt.fq, q)
		}
	}
}

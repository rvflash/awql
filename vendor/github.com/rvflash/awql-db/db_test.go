package awql_db_test

import (
	"fmt"
	"testing"

	"github.com/rvflash/awql-db"
)

func TestNewDb(t *testing.T) {
	db := awql_db.NewDb("v201609", "")
	if err := db.Load(); err != nil {
		t.Errorf("Expected no error on loading tables and views properties, received %s", err)
	}
	if _, err := db.Table("AD_PERFORMANCE_REPORT"); err != nil {
		t.Errorf("Expected a table named AD_PERFORMANCE_REPORT, received %s", err)
	}
	if tables := db.TablesPrefixedBy("CAMPAIGN"); len(tables) != 8 {
		t.Error("Expected only 8 tables prefixed by 'CAMPAIGN'")
	}
	if tables := db.TablesSuffixedBy("_REPORT"); len(tables) != 45 {
		t.Error("Expected only 45 tables suffixed by '_REPORT'")
	}
	if tables := db.TablesContains("NEGATIVE"); len(tables) != 3 {
		t.Error("Expected only 3 tables with 'NEGATIVE' in its name")
	}
	if tables := db.TablesWithColumn("TrackingUrlTemplate"); len(tables) != 13 {
		t.Error("Expected 13 tables using TrackingUrlTemplate as column")
	}
}

func TestIsSupported(t *testing.T) {
	var vTests = []struct {
		v  string
		ok bool
	}{
		{"", false},
		{"v201607", false},
		{"v201609", true},
	}

	for i, vt := range vTests {
		if ok := awql_db.IsSupported(vt.v); vt.ok != ok {
			t.Errorf("%d. Expected '%t' with '%s', received '%t'", i, vt.ok, vt.v, ok)
		}
	}
}

func ExampleSupportedVersions() {
	fmt.Println(awql_db.SupportedVersions())
	// Output: [v201609]
}

func ExampleDatabase_Tables() {
	db := awql_db.NewDb("v201609", "")
	// Ignores the errors for the demo.
	db.Load()

	tb, _ := db.Tables()
	for _, t := range tb {
		fmt.Println(t.SourceName())
	}
	// Output:
	// ACCOUNT_PERFORMANCE_REPORT
	// AD_CUSTOMIZERS_FEED_ITEM_REPORT
	// AD_PERFORMANCE_REPORT
	// ADGROUP_PERFORMANCE_REPORT
	// AGE_RANGE_PERFORMANCE_REPORT
	// AUDIENCE_PERFORMANCE_REPORT
	// AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT
	// BID_GOAL_PERFORMANCE_REPORT
	// BUDGET_PERFORMANCE_REPORT
	// CALL_METRICS_CALL_DETAILS_REPORT
	// CAMPAIGN_AD_SCHEDULE_TARGET_REPORT
	// CAMPAIGN_LOCATION_TARGET_REPORT
	// CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT
	// CAMPAIGN_NEGATIVE_LOCATIONS_REPORT
	// CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT
	// CAMPAIGN_PERFORMANCE_REPORT
	// CAMPAIGN_PLATFORM_TARGET_REPORT
	// CAMPAIGN_SHARED_SET_REPORT
	// CLICK_PERFORMANCE_REPORT
	// CREATIVE_CONVERSION_REPORT
	// CRITERIA_PERFORMANCE_REPORT
	// DESTINATION_URL_REPORT
	// DISPLAY_KEYWORD_PERFORMANCE_REPORT
	// DISPLAY_TOPICS_PERFORMANCE_REPORT
	// FINAL_URL_REPORT
	// GENDER_PERFORMANCE_REPORT
	// GEO_PERFORMANCE_REPORT
	// KEYWORDLESS_CATEGORY_REPORT
	// KEYWORDLESS_QUERY_REPORT
	// KEYWORDS_PERFORMANCE_REPORT
	// LABEL_REPORT
	// PAID_ORGANIC_QUERY_REPORT
	// PARENTAL_STATUS_PERFORMANCE_REPORT
	// PLACEHOLDER_FEED_ITEM_REPORT
	// PLACEHOLDER_REPORT
	// PLACEMENT_PERFORMANCE_REPORT
	// PRODUCT_PARTITION_REPORT
	// SEARCH_QUERY_PERFORMANCE_REPORT
	// SHARED_SET_CRITERIA_REPORT
	// SHARED_SET_REPORT
	// SHOPPING_PERFORMANCE_REPORT
	// URL_PERFORMANCE_REPORT
	// USER_AD_DISTANCE_REPORT
	// TOP_CONTENT_PERFORMANCE_REPORT
	// VIDEO_PERFORMANCE_REPORT
}

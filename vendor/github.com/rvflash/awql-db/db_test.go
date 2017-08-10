package awqldb_test

import (
	"fmt"
	"testing"

	db "github.com/rvflash/awql-db"
)

func TestOpen(t *testing.T) {
	d, err := db.Open("v201609")
	if err != nil {
		t.Fatalf("Expected no error on loading tables and views properties, received %s", err)
	}
	if _, err := d.Table("AD_PERFORMANCE_REPORT"); err != nil {
		t.Errorf("Expected a table named AD_PERFORMANCE_REPORT, received %s", err)
	}
	if tables := d.TablesPrefixedBy("CAMPAIGN"); len(tables) != 8 {
		t.Error("Expected only 8 tables prefixed by 'CAMPAIGN'")
	}
	if tables := d.TablesSuffixedBy("_REPORT"); len(tables) != 45 {
		t.Error("Expected only 45 tables suffixed by '_REPORT'")
	}
	if tables := d.TablesContains("NEGATIVE"); len(tables) != 3 {
		t.Error("Expected only 3 tables with 'NEGATIVE' in its name")
	}
	if tables := d.TablesWithColumn("TrackingUrlTemplate"); len(tables) != 13 {
		t.Error("Expected 13 tables using TrackingUrlTemplate as column")
	}
}

func TestDatabase_HasVersion(t *testing.T) {
	var vTests = []struct {
		v  string
		ok bool
	}{
		{"", false},
		{"v201607", false},
		{"v201609", true},
		{"v201702", true},
		{"v201705", true},
		{"v201708", true},
	}

	d, err := db.Open("")
	if err != nil {
		t.Fatalf("Expected no error with no version in DSN, received %s", err)
	}
	for i, vt := range vTests {
		if ok := d.HasVersion(vt.v); vt.ok != ok {
			t.Errorf("%d. Expected '%t' with '%s', received '%t'", i, vt.ok, vt.v, ok)
		}
	}
}

func ExampleDatabase_SupportedVersions() {
	d, _ := db.Open("")
	fmt.Println(d.SupportedVersions())
	// Output: [v201609 v201702 v201705 v201708]
}

func ExampleDatabase_Tables() {
	// Ignores errors for the demo.
	d, _ := db.Open("v201702")
	tb, _ := d.Tables()
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

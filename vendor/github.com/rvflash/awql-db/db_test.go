package awqldb_test

import (
	"fmt"
	"testing"

	db "github.com/rvflash/awql-db"
)

func TestOpen(t *testing.T) {
	d, err := db.Open("v201806")
	if err != nil {
		t.Fatalf("Expected no error on loading tables and views properties, received %s", err)
	}
	if _, err := d.Table("AD_PERFORMANCE_REPORT"); err != nil {
		t.Errorf("Expected a table named AD_PERFORMANCE_REPORT, received %s", err)
	}
	tables := d.TablesPrefixedBy("CAMPAIGN")
	if l := len(tables); l != 7 {
		t.Errorf("Expected only 8 tables prefixed by 'CAMPAIGN': got=%v", l)
	}
	tables = d.TablesSuffixedBy("_REPORT")
	if l := len(tables); l != 45 {
		t.Errorf("Expected only 45 tables suffixed by '_REPORT': got=%v", l)
	}
	tables = d.TablesContains("NEGATIVE")
	if l := len(tables); l != 3 {
		t.Errorf("Expected only 3 tables with 'NEGATIVE' in its name: got=%v", l)
	}
	tables = d.TablesWithColumn("TrackingUrlTemplate")
	if l := len(tables); l != 13 {
		t.Errorf("Expected 13 tables using TrackingUrlTemplate as column: got=%v", l)
	}
}

func TestDatabase_HasVersion(t *testing.T) {
	var vTests = []struct {
		v  string
		ok bool
	}{
		{"", false},
		{"v201607", false},
		{"v201609", false},
		{"v201702", false},
		{"v201705", false},
		{"v201708", false},
		{"v201710", true},
		{"v201802", true},
		{"v201806", true},
	}

	d, err := db.Open("")
	if err != nil {
		t.Fatalf("Expected no error with no version in DSN, received: %q", err)
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
	// Output: [v201710 v201802 v201806]
}

func ExampleDatabase_Tables() {
	// Ignores errors for the demo.
	d, _ := db.Open("v201806")
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
	// LANDING_PAGE_REPORT
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

package awql_test

import (
	"database/sql/driver"
	"reflect"
	"testing"

	"github.com/rvflash/awql-driver"
)

// TestStmt_Bind tests the method Bind.
func TestStmt_Bind(t *testing.T) {
	var stmtTests = []struct {
		s *awql.Stmt
		q string
		a []driver.Value
		e error
	}{
		{s: &awql.Stmt{}},
		{
			s: &awql.Stmt{SrcQuery: "select Cost FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = ?"},
			q: `select Cost FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = 12345678`,
			a: []driver.Value{12345678},
		},
		{
			s: &awql.Stmt{SrcQuery: "select Cost FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = ? AND CampaignStatus = ?"},
			a: []driver.Value{12345678},
			e: awql.ErrQueryBinding,
		},
		{
			s: &awql.Stmt{SrcQuery: "select Cost FROM AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT where CampaignId = ? AND IsPathExcluded = ?"},
			a: []driver.Value{12345678, true},
			q: `select Cost FROM AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT where CampaignId = 12345678 AND IsPathExcluded = TRUE`,
		},
		{
			s: &awql.Stmt{SrcQuery: "select Cost FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = ? AND CampaignName = ? AND Amount > ?"},
			a: []driver.Value{12345678, "rv", 12.3},
			q: `select Cost FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = 12345678 AND CampaignName = "rv" AND Amount > 12.300000`,
		},
	}

	for i, st := range stmtTests {
		err := st.s.Bind(st.a)
		if !reflect.DeepEqual(err, st.e) {
			t.Fatalf("%d. Expected %v as binding error, received %v", i, st.e, err)
		} else if st.e == nil && st.s.SrcQuery != st.q {
			t.Errorf("%d. Expected %s as query after binding, received %v", i, st.q, st.s.SrcQuery)
		}
	}
}

// TestStmt_Close tests the method Close.
func TestStmt_Close(t *testing.T) {
	s := &awql.Stmt{}
	if err := s.Close(); err != nil {
		t.Fatalf("Expected nil as return when we close a statement, received %v", err)
	}
}

// TestStmt_Exec tests the method Exec.
func TestStmt_Exec(t *testing.T) {
	s := &awql.Stmt{}
	rs, err := s.Exec(nil)
	if rs != nil || err != driver.ErrSkip {
		t.Fatalf("Expected nil and driver.ErrSkip, received %v and %v", rs, err)
	}
}

// TestStmt_Hash tests the method Hash.
func TestStmt_Hash(t *testing.T) {
	var stmtTests = []struct {
		s *awql.Stmt
		h string
		e error
	}{
		{s: &awql.Stmt{}, e: awql.ErrQuery},
		{s: &awql.Stmt{nil, "Select CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT"}, h: "9028008530673448812"},
		{s: &awql.Stmt{nil, "select CampaignId from CAMPAIGN_PERFORMANCE_REPORT"}, h: "9028008530673448812"},
	}
	for i, st := range stmtTests {
		hash, err := st.s.Hash()
		if !reflect.DeepEqual(err, st.e) {
			t.Fatalf("%d. Expected %v as hashing error, received %v", i, st.e, err)
		} else if hash != st.h {
			t.Errorf("%d. Expected %s as hash of %s, received %v", i, st.h, st.s.SrcQuery, hash)
		}
	}
}

// TestStmt_NumInput tests the method NumInput.
func TestStmt_NumInput(t *testing.T) {
	var stmtTests = []struct {
		s *awql.Stmt
		n int
	}{
		{s: &awql.Stmt{}},
		{s: &awql.Stmt{nil, "select CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = ?"}, n: 1},
		{s: &awql.Stmt{nil, "select CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT where CampaignId = ? AND CampaignStatus = ?"}, n: 2},
	}
	for i, st := range stmtTests {
		if st.s.NumInput() != st.n {
			t.Errorf("%d. Expected %d inputs, received %v", i, st.s.NumInput(), st.n)
		}
	}
}

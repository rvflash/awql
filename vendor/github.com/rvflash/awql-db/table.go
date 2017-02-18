package awqldb

import (
	"fmt"
	"strings"

	awql "github.com/rvflash/awql-parser"
)

// Outputs format.
const (
	newline = "\n"
	sep     = "  "
	dsep    = sep + sep
	qsep    = dsep + dsep
)

// DataTable is the interface that must be implemented by a table.
// It implements the awql.CreateViewStmt and fmt.Stringer interfaces.
type DataTable interface {
	awql.CreateViewStmt
	AggregateFieldName() string
	ColumnsPrefixedBy(pattern string) []awql.DynamicField
	Field(name string) (Field, error)
	IsView() bool
}

// Table represents a data table.
// It implements the DataTable interface.
type Table struct {
	Name       string
	PrimaryKey string `yaml:"aggr,omitempty"`
	Cols       []Column
	View       View `yaml:",omitempty"`
}

// AggregateFieldName returns the name of the primary key.
func (t Table) AggregateFieldName() string {
	return t.PrimaryKey
}

// Columns returns the list of the columns of the table.
func (t Table) Columns() []awql.DynamicField {
	fields := make([]awql.DynamicField, len(t.Cols))
	for i, f := range t.Cols {
		fields[i] = f
	}
	return fields
}

// ColumnsPrefixedBy returns the list of table's columns prefixed by this pattern.
func (t Table) ColumnsPrefixedBy(pattern string) (columns []awql.DynamicField) {
	for _, c := range t.Cols {
		if strings.HasPrefix(c.Head, pattern) {
			columns = append(columns, c)
		}
	}
	return
}

// Field returns the field with this column name or an error.
func (t Table) Field(name string) (Field, error) {
	for _, c := range t.Cols {
		if c.Head == name {
			return c, nil
		}
	}
	return nil, ErrUnknownColumn
}

// IsView returns true if the data is not a report but a data view.
func (t Table) IsView() bool {
	return t.View.Name != ""
}

// SourceName returns the name of the table.
func (t Table) SourceName() string {
	return t.Name
}

// SourceQuery returns the source query, base of the view to create.
func (t Table) SourceQuery() awql.SelectStmt {
	return t.View
}

// ReplaceMode returns true if it is required to replace the existing view.
// To skip. Method of awql.DataStmt interface not implemented.
// Returns only false.
func (t Table) ReplaceMode() bool {
	return false
}

// String returns a Yaml string representation of a table.
// It implements fmt.Stringer interface.
//
// Output example:
//   - name: ADGROUP_DAILY
//     rprt: ADGROUP_PERFORMANCE_REPORT
//     cols:
//       - name: AdGroupId
//         psnm: Id
//     view:
//       name: ADGROUP_DAILY
//       rprt: ADGROUP_PERFORMANCE_REPORT
//       cols:
//         - name: AdGroupId
//       where:
//         - coln: Impressions
//           oprt: >
//           cval: [0]
//           lval: true
//       during: [LAST_30_DAYS]
//       group: []
//       order:
//         - cpos: 1
//           desc: false
//       limit:
//         offs: 0
//         rcnt: 15
//
func (t Table) String() string {
	s := sep + "- name: " + t.Name + newline
	s += dsep + "aggr: " + t.PrimaryKey + newline

	// Fields.
	s += dsep + "cols:" + newline
	for _, c := range t.Cols {
		s += c.String(false)
	}

	// Data source
	if t.IsView() {
		s += t.View.String()
	}
	return s
}

// VerticalOutput returns true if the G modifier is required.
// To skip. Method of awql.DataStmt interface not implemented.
// Returns only false.
func (t Table) VerticalOutput() bool {
	return false
}

// Field is the interface that must be implemented by a column.
// It implements the awql.DynamicField interface.
type Field interface {
	awql.DynamicField
	IsSegment() bool
	Kind() string
	NotCompatibleColumns() []string
	SupportsZeroImpressions() bool
	ValueList() []string
	String(viewMode bool) string
}

// Column represents a column extracted from the Yaml configuration file.
// It implements the Field interface.
type Column struct {
	Head            string   `yaml:"name"`
	Label           string   `yaml:"psnm,omitempty"`
	Type            string   `yaml:"kind"`
	Segmented       bool     `yaml:"sgmt,omitempty"`
	ZeroImpressions bool     `yaml:"zero,omitempty"`
	Enum            []string `yaml:"enum,omitempty,flow"`
	Incompatibles   []string `yaml:"notc,omitempty,flow"`
	Method          string   `yaml:"func,omitempty"`
	Unique          bool     `yaml:"uniq,omitempty"`
}

// Name returns the column's name.
func (c Column) Name() string {
	return c.Head
}

// Alias returns the pseudonym of the name.
func (c Column) Alias() string {
	return c.Label
}

// Distinct return true if the must be grouped by it.
func (c Column) Distinct() bool {
	return c.Unique
}

// IsSegment returns true if the column is a segmented field.
func (c Column) IsSegment() bool {
	return c.Segmented
}

// Kind returns the column's type.
func (c Column) Kind() string {
	return c.Type
}

// NotCompatibleColumns returns the list of column's names incompatible.
func (c Column) NotCompatibleColumns() []string {
	return c.Incompatibles
}

// SupportsZeroImpressions returns true if the columns
// does not implicitly exclude zero impressions.
func (c Column) SupportsZeroImpressions() bool {
	return c.ZeroImpressions
}

// String returns a Yaml string representation of a column.
func (c Column) String(viewMode bool) string {
	msep := dsep
	if viewMode {
		// Adapts the position of columns in function of the kind of table.
		msep = dsep + sep
	}
	s := sep + msep + "- name: " + c.Name() + newline

	// Optional properties
	if c.Alias() != "" {
		s += dsep + msep + "psnm: " + c.Alias() + newline
	}
	if c.Kind() != "" {
		s += dsep + msep + "kind: " + c.Kind() + newline
	}
	if c.IsSegment() {
		s += dsep + msep + "sgmt: true" + newline
	}
	if c.SupportsZeroImpressions() {
		s += dsep + msep + "zero: true" + newline
	}
	if val := c.ValueList(); len(val) > 0 {
		s += dsep + msep + "enum: [ " + strings.Join(val, ", ") + " ]" + newline
	}
	if val := c.NotCompatibleColumns(); len(val) > 0 {
		s += dsep + msep + "notc: [ " + strings.Join(val, ", ") + " ]" + newline
	}
	if val, ok := c.UseFunction(); ok {
		s += dsep + msep + "func: " + val + newline
	}
	if c.Distinct() {
		s += dsep + msep + "uniq: true" + newline
	}

	return s
}

// UseFunction return the method to use on it.
// The second parameters indicates if it is required.
func (c Column) UseFunction() (string, bool) {
	return c.Method, c.Method != ""
}

// ValueList returns in case of enum column, the available list of its values.
func (c Column) ValueList() []string {
	return c.Enum
}

// Condition represents a where clause.
// It implements the awql.Condition interface and the fmt.Stringer interface.
type Condition struct {
	ColumnName     string   `yaml:"coln"`
	Sign           string   `yaml:"oprt"`
	ColumnValue    []string `yaml:"cval"`
	IsValueLiteral bool     `yaml:"lval,omitempty"`
}

// Operator returns the operator of the condition.
func (c Condition) Operator() string {
	return c.Sign
}

// Name returns the columns used in the condition.
func (c Condition) Name() string {
	return c.ColumnName
}

// Alias returns the column alias.
// To skip. Func of awql.DataStmt interface not implemented.
func (c Condition) Alias() string {
	return ""
}

// String returns a Yaml string representation of a where clause.
// Output:
//         - coln: Impressions
//           oprt: >
//           lval: true
//           cval: [ 0 ]
func (c Condition) String() string {
	s := qsep + sep + "- coln: " + c.Name() + newline
	s += qsep + dsep + "oprt: " + c.Operator() + newline
	val, literal := c.Value()
	if literal {
		s += qsep + dsep + "lval: true" + newline
	}
	s += qsep + dsep + "cval: [ " + strings.Join(val, ", ") + " ]" + newline

	return s
}

// Value returns the filtering value.
func (c Condition) Value() ([]string, bool) {
	return c.ColumnValue, c.IsValueLiteral
}

// GroupBy represents an group by clause.
// It implements the awql.FieldPosition interface and the fmt.Stringer interface.
type GroupBy struct {
	ColumnName     string `yaml:"coln,omitempty"`
	ColumnAlias    string `yaml:"psnm,omitempty"`
	ColumnPosition int    `yaml:"cpos"`
}

// Name returns the columns used in the condition.
func (g GroupBy) Name() string {
	return g.ColumnName
}

// Alias returns the column alias.
func (g GroupBy) Alias() string {
	return g.ColumnAlias
}

// Position returns the position of the field in the query.
func (g GroupBy) Position() int {
	return g.ColumnPosition
}

// String returns a Yaml string representation of a group by clause.
// Output: 2
func (g GroupBy) String() string {
	return string(g.Position())
}

// Order represents an order clause.
// It implements the awql.Orderer interface and the fmt.Stringer interface.
type Order struct {
	ColumnName     string `yaml:"coln,omitempty"`
	ColumnAlias    string `yaml:"psnm,omitempty"`
	ColumnPosition int    `yaml:"cpos"`
	SortDesc       bool   `yaml:"desc,omitempty"`
}

// Name returns the column name.
func (o Order) Name() string {
	return o.ColumnName
}

// Alias returns the column alias.
func (o Order) Alias() string {
	return o.ColumnAlias
}

// Position returns the position of the field in the query.
func (o Order) Position() int {
	return o.ColumnPosition
}

//SortDescending returns true if the column needs to be sort by desc.
func (o Order) SortDescending() bool {
	return o.SortDesc
}

// String returns a Yaml string representation of an order clause.
// Output:
//         - cpos: 1
//           desc: false
func (o Order) String() string {
	s := qsep + sep + "- cpos: " + string(o.Position()) + newline
	if o.SortDescending() {
		s += qsep + dsep + "desc: true" + newline
	}

	return s
}

// Limit represents the limit clause.
type Limit struct {
	Offset   int `yaml:"oset,omitempty"`
	RowCount int `yaml:"rcnt"`
}

// String returns a Yaml string representation of the limit clause.
// Output:
//       limit:
//         offs: 0
//         rcnt: 15
func (l Limit) String() (s string) {
	if l.RowCount == 0 {
		return
	}
	s = qsep + "limit:" + newline
	s += qsep + sep + "offs:" + string(l.Offset) + newline
	s += qsep + sep + "rcnt:" + string(l.RowCount) + newline

	return
}

// View represents a view.
// It implements the awql.SelectStmt interface.
type View struct {
	Name       string
	PrimaryKey string `yaml:"aggr,omitempty"`
	Cols       []Column
	Where      []Condition `yaml:",omitempty"`
	During     []string    `yaml:",omitempty"`
	GroupBy    []GroupBy   `yaml:"group,omitempty"`
	OrderBy    []Order     `yaml:"order,omitempty"`
	Limit      Limit       `yaml:",omitempty"`
}

// Columns returns the list of the columns of the table.
func (t View) Columns() []awql.DynamicField {
	fields := make([]awql.DynamicField, len(t.Cols))
	for i, f := range t.Cols {
		fields[i] = f
	}
	return fields
}

// ColumnsPrefixedBy returns the list of table's columns prefixed by this pattern.
func (t View) ColumnsPrefixedBy(pattern string) (columns []awql.DynamicField) {
	for _, c := range t.Cols {
		if strings.HasPrefix(c.Head, pattern) {
			columns = append(columns, c)
		}
	}
	return
}

// ConditionList returns the condition list.
func (t View) ConditionList() []awql.Condition {
	where := make([]awql.Condition, len(t.Where))
	for i, w := range t.Where {
		where[i] = w
	}
	return where
}

// DuringList returns the during (date range).
func (t View) DuringList() []string {
	return t.During
}

// FieldByName returns the field with this column name or an error.
func (t View) FieldByName(column string) (Field, error) {
	for _, c := range t.Cols {
		if c.Head == column {
			return c, nil
		}
	}
	return nil, ErrUnknownColumn
}

// LegacyString returns an empty string.
// To skip. Method of awql.DataStmt interface not implemented.
func (t View) LegacyString() string {
	return ""
}

// GroupList returns the group by columns.
func (t View) GroupList() []awql.FieldPosition {
	group := make([]awql.FieldPosition, len(t.GroupBy))
	for i, g := range t.GroupBy {
		group[i] = g
	}
	return group
}

// OrderList returns the order by columns.
func (t View) OrderList() []awql.Orderer {
	order := make([]awql.Orderer, len(t.OrderBy))
	for i, o := range t.OrderBy {
		order[i] = o
	}
	return order
}

// PageSize returns the row count.
func (t View) PageSize() (int, bool) {
	return t.Limit.RowCount, t.Limit.RowCount > 0
}

// SourceName returns the name of the table.
func (t View) SourceName() string {
	return t.Name
}

// StartIndex returns the start index.
func (t View) StartIndex() int {
	return t.Limit.Offset
}

// String returns a Yaml string representation of the view.
// It implements fmt.Stringer interface.
//
// Output example:
//     view:
//       name: ADGROUP_DAILY
//       rprt: ADGROUP_PERFORMANCE_REPORT
//       cols:
//         - name: AdGroupId
//       where:
//         - coln: Impressions
//           oprt: >
//           lval: true
//           cval: [0]
//       during: [LAST_30_DAYS]
//       group: []
//       order:
//         - cpos: 1
//           desc: false
//       limit:
//         offs: 0
//         rcnt: 15
//
func (t View) String() string {
	s := dsep + sep + "view:" + newline
	s += qsep + "name: " + t.Name + newline
	s += qsep + "aggr: " + t.PrimaryKey + newline

	// Fields.
	s += qsep + "cols:" + newline
	for _, c := range t.Cols {
		s += c.String(true)
	}

	// Where clause.
	if where := t.Where; len(where) > 0 {
		s += qsep + "where:" + newline
		for _, w := range where {
			s += w.String()
		}
	}

	// During clause.
	if during := t.During; len(during) > 0 {
		s += qsep + "during: [ " + strings.Join(during, ", ") + " ]" + newline
	}

	// Group by clause.
	group := t.GroupBy
	if size := len(group); size > 0 {
		val := make([]string, size)
		for i, o := range group {
			val[i] = o.String()
		}
		s += qsep + "group: [ " + strings.Join(val, ", ") + " ]" + newline
	}

	// Order by clause.
	if order := t.OrderBy; len(order) > 0 {
		s += qsep + "order:" + newline
		for _, o := range order {
			s += o.String()
		}
	}

	// Limit clause.
	s += t.Limit.String()

	return s
}

// VerticalOutput returns true if the G modifier is required.
// To skip. Method of awql.DataStmt interface not implemented.
// Returns only false.
func (t View) VerticalOutput() bool {
	return false
}

// newColumn returns an instance of Column.
func (t Table) newColumn(src, alias awql.DynamicField) (Column, error) {
	col := Column{
		Head:   src.Name(),
		Label:  alias.Name(),
		Unique: src.Distinct(),
	}
	col.Method, _ = src.UseFunction()

	// Loads columns properties.
	spec, err := t.Field(col.Head)
	if err != nil {
		return col, fmt.Errorf("%s (%v)", err, col.Head)
	}
	col.Type = spec.Kind()
	col.Segmented = spec.IsSegment()
	col.ZeroImpressions = spec.SupportsZeroImpressions()
	col.Enum = spec.ValueList()
	col.Incompatibles = spec.NotCompatibleColumns()

	return col, nil
}

// newCondition returns an instance of Condition.
func newCondition(c awql.Condition) Condition {
	cnd := Condition{
		ColumnName: c.Name(),
		Sign:       c.Operator(),
	}
	cnd.ColumnValue, cnd.IsValueLiteral = c.Value()

	return cnd
}

// newGroupBy returns an instance of GroupBy.
func newGroupBy(g awql.FieldPosition) GroupBy {
	return GroupBy{
		ColumnName:     g.Name(),
		ColumnAlias:    g.Alias(),
		ColumnPosition: g.Position(),
	}
}

// newOrderBy returns an instance of Order.
func newOrderBy(o awql.Orderer) Order {
	return Order{
		ColumnName:     o.Name(),
		ColumnAlias:    o.Alias(),
		ColumnPosition: o.Position(),
		SortDesc:       o.SortDescending(),
	}
}

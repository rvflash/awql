package awqlparse

import "fmt"

// Field is the interface that must be implemented by a column.
type Field interface {
	Name() string
	Alias() string
}

// Column represents a column.
// It implements the DynamicColumn interface.
type Column struct {
	ColumnName,
	ColumnAlias string
}

// NewColumn returns a pointer to a new Column.
func NewColumn(name, alias string) *Column {
	return &Column{ColumnName: name, ColumnAlias: alias}
}

// Name returns the column name.
func (c *Column) Name() string {
	return c.ColumnName
}

// Alias returns the column alias.
func (c *Column) Alias() string {
	return c.ColumnAlias
}

// FieldPosition is the interface that must be implemented by a query's column.
type FieldPosition interface {
	Field
	Position() int
}

// ColumnPosition represents a column with its position in the query.
// It implements the FieldPosition interface.
type ColumnPosition struct {
	*Column
	ColumnPos int
}

// NewColumnPosition returns a pointer to a new ColumnPosition.
func NewColumnPosition(col *Column, pos int) *ColumnPosition {
	return &ColumnPosition{Column: col, ColumnPos: pos}
}

// Position returns the position of the field in the query.
func (c *ColumnPosition) Position() int {
	return c.ColumnPos
}

// DynamicField is the interface that must be implemented by a query's field.
type DynamicField interface {
	Field
	UseFunction() (string, bool)
	Distinct() bool
}

// DynamicColumn represents a field.
// It implements the DynamicField interface.
type DynamicColumn struct {
	*Column
	Method string
	Unique bool
}

// NewDynamicColumn returns a pointer to a new DynamicColumn.
func NewDynamicColumn(col *Column, method string, unique bool) *DynamicColumn {
	return &DynamicColumn{Column: col, Method: method, Unique: unique}
}

// UseFunction returns the name of the method to apply of the column.
// The second parameter indicates if a method is used.
func (c *DynamicColumn) UseFunction() (string, bool) {
	return c.Method, c.Method != ""
}

// Distinct returns true if the column value needs to be unique.
func (c *DynamicColumn) Distinct() bool {
	return c.Unique
}

// Condition is the interface that must be implemented by a condition.
type Condition interface {
	Field
	Operator() string
	Value() (value []string, literal bool)
}

// Where represents a condition in where clause.
// It implements the Condition interface.
type Where struct {
	*Column
	Sign           string
	ColumnValue    []string
	IsValueLiteral bool
}

// Operator returns the condition's operator
func (c *Where) Operator() string {
	return c.Sign
}

// Value returns the column's value of the condition.
func (c *Where) Value() ([]string, bool) {
	return c.ColumnValue, c.IsValueLiteral
}

// Pattern represents a LIKE clause.
type Pattern struct {
	Equal, Prefix, Contains, Suffix string
}

// Orderer is the interface that must be implemented by an ordering.
type Orderer interface {
	FieldPosition
	SortDescending() bool
}

// Order represents an order by clause.
// It implements the Orderer interface.
type Order struct {
	*ColumnPosition
	SortDesc bool
}

// SortDescending returns true if the column needs to be sort by desc.
func (o *Order) SortDescending() bool {
	return o.SortDesc
}

// Limit represents a limit clause.
type Limit struct {
	Offset, RowCount int
	WithRowCount     bool
}

// Stmt formats the query output.
type Stmt interface {
	VerticalOutput() bool
	fmt.Stringer
}

// Statement enables to format the query output.
type Statement struct {
	GModifier bool
}

// VerticalOutput returns true if the G modifier is required.
// It implements the Stmt interface.
func (s Statement) VerticalOutput() bool {
	return s.GModifier
}

// DataStmt represents a AWQL base statement.
// By design, only the SELECT statement is supported by Adwords.
// The AWQL command line tool extends it with others SQL grammar.
type DataStmt interface {
	Columns() []DynamicField
	SourceName() string
	Stmt
}

// DataStatement represents a AWQL base statement.
// It implements the DataStmt interface.
type DataStatement struct {
	Fields    []DynamicField
	TableName string
	Statement
}

// Columns returns the list of table fields.
func (s DataStatement) Columns() []DynamicField {
	return s.Fields
}

// SourceName returns the table's name.
func (s DataStatement) SourceName() string {
	return s.TableName
}

/*
SelectStmt exposes the interface of AWQL Select Statement

This is a extended version of the original grammar in order to manage all
the possibilities of the AWQL command line tool.

SelectClause     : SELECT ColumnList
FromClause       : FROM SourceName
WhereClause      : WHERE ConditionList
DuringClause     : DURING DateRange
GroupByClause    : GROUP BY Grouping (, Grouping)*
OrderByClause    : ORDER BY Order (, Order)*
LimitClause      : LIMIT StartIndex , PageSize

ConditionList    : Condition (AND Condition)*
Condition        : ColumnName Operator Value
Value            : ValueLiteral | String | ValueLiteralList | StringList
Order         : ColumnName (DESC | ASC)?
DateRange        : DateRangeLiteral | Date,Date
ColumnList       : ColumnName (, ColumnName)*
ColumnName       : Literal
TableName        : Literal
StartIndex       : Non-negative integer
PageSize         : Non-negative integer

Operator         : = | != | > | >= | < | <= | IN | NOT_IN | STARTS_WITH | STARTS_WITH_IGNORE_CASE |
									CONTAINS | CONTAINS_IGNORE_CASE | DOES_NOT_CONTAIN | DOES_NOT_CONTAIN_IGNORE_CASE
String           : StringSingleQ | StringDoubleQ
StringSingleQ    : '(char)'
StringDoubleQ    : "(char)"
StringList       : [ String (, String)* ]
ValueLiteral     : [a-zA-Z0-9_.]*
ValueLiteralList : [ ValueLiteral (, ValueLiteral)* ]
Literal          : [a-zA-Z0-9_]*
DateRangeLiteral : TODAY | YESTERDAY | LAST_7_DAYS | THIS_WEEK_SUN_TODAY | THIS_WEEK_MON_TODAY | LAST_WEEK |
									 LAST_14_DAYS | LAST_30_DAYS | LAST_BUSINESS_WEEK | LAST_WEEK_SUN_SAT | THIS_MONTH
Date             : 8-digit integer: YYYYMMDD
*/
type SelectStmt interface {
	DataStmt
	ConditionList() []Condition
	DuringList() []string
	GroupList() []FieldPosition
	OrderList() []Orderer
	StartIndex() int
	PageSize() (int, bool)
	LegacyString() string
}

// SelectStatement represents a AWQL SELECT statement.
// SELECT...FROM...WHERE...DURING...GROUP BY...ORDER BY...LIMIT...
// It implements the SelectStmt interface.
type SelectStatement struct {
	DataStatement
	Where   []Condition
	During  []string
	GroupBy []FieldPosition
	OrderBy []Orderer
	Limit
}

// ConditionList returns the condition list.
func (s SelectStatement) ConditionList() []Condition {
	return s.Where
}

// DuringList returns the during (date range).
func (s SelectStatement) DuringList() []string {
	return s.During
}

// GroupList returns the group by columns.
func (s SelectStatement) GroupList() []FieldPosition {
	return s.GroupBy
}

// OrderList returns the order by columns.
func (s SelectStatement) OrderList() []Orderer {
	return s.OrderBy
}

// StartIndex returns the start index.
func (s SelectStatement) StartIndex() int {
	return s.Offset
}

// PageSize returns the row count.
func (s SelectStatement) PageSize() (int, bool) {
	return s.RowCount, s.WithRowCount
}

/*
CreateViewStmt exposes the interface of AWQL Create View Statement

Not supported natively by Adwords API. Used by the following AWQL command line tool:
https://github.com/rvflash/awql/

CreateClause     : CREATE (OR REPLACE)* VIEW DestinationName (**(**ColumnList**)**)*
FromClause       : AS SelectClause
*/
type CreateViewStmt interface {
	DataStmt
	ReplaceMode() bool
	SourceQuery() SelectStmt
}

// CreateViewStatement represents a AWQL CREATE VIEW statement.
// CREATE...OR REPLACE...VIEW...AS
// It implements the CreateViewStmt interface.
type CreateViewStatement struct {
	DataStatement
	Replace bool
	View    *SelectStatement
}

// ReplaceMode returns true if it is required to replace the existing view.
func (s CreateViewStatement) ReplaceMode() bool {
	return s.Replace
}

// SourceQuery returns the source query, base of the view to create.
func (s CreateViewStatement) SourceQuery() SelectStmt {
	return s.View
}

// FullStmt proposes the full statement mode.
type FullStmt interface {
	FullMode() bool
}

// FullStatement enables a AWQL FULL mode.
// It implements the FullStmt interface.
type FullStatement struct {
	Full bool
}

// FullMode returns true if the full display is required.
func (s FullStatement) FullMode() bool {
	return s.Full
}

/*
DescribeStmt exposes the interface of AWQL Describe Statement

Not supported natively by Adwords API. Used by the following AWQL command line tool:
https://github.com/rvflash/awql/

DescribeClause   : (DESCRIBE | DESC) (FULL)* SourceName (ColumnName)*
*/
type DescribeStmt interface {
	DataStmt
	FullStmt
}

// DescribeStatement represents a AWQL DESC statement.
// DESC...FULL
// It implements the DescribeStmt interface.
type DescribeStatement struct {
	FullStatement
	DataStatement
}

/*
ShowStmt exposes the interface of AWQL Show Statement

Not supported natively by Adwords API. Used by the following AWQL command line tool:
https://github.com/rvflash/awql/

ShowClause   : SHOW (FULL)* TABLES
WithClause   : WITH ColumnName
LikeClause   : LIKE String
*/
type ShowStmt interface {
	FullStmt
	LikePattern() (p Pattern, used bool)
	WithFieldName() (name string, used bool)
	Stmt
}

// ShowStatement represents a AWQL SHOW statement.
// SHOW...FULL...TABLES...LIKE...WITH
// It implements the ShowStmt interface.
type ShowStatement struct {
	FullStatement
	Like    Pattern
	With    string
	UseWith bool
	Statement
}

// LikePattern returns the pattern used for a like query on the table list.
// If the second parameter is on, the like clause has been used.
func (s ShowStatement) LikePattern() (Pattern, bool) {
	var used bool
	switch {
	case s.Like.Equal != "":
		used = true
	case s.Like.Contains != "":
		used = true
	case s.Like.Prefix != "":
		used = true
	case s.Like.Suffix != "":
		used = true
	}
	return s.Like, used
}

// WithFieldName returns the column name used to search table with this column.
func (s ShowStatement) WithFieldName() (string, bool) {
	return s.With, s.UseWith
}

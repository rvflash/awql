package driver

import (
	"database/sql"
	"database/sql/driver"
	"fmt"
	"hash/fnv"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
	parser "github.com/rvflash/awql-parser"
	cache "github.com/rvflash/csv-cache"
)

// Stmt is a prepared statement.
type Stmt struct {
	si *awql.Stmt
	db *db.Database
	fc *cache.Cache
	p  parser.Stmt
	id string
}

// Bind applies the required argument replacements on the query.
func (s *Stmt) Bind(args []driver.Value) error {
	// Binds all arguments on the query.
	if err := s.si.Bind(args); err != nil {
		return err
	}
	// Parses the statement to manage it as expected by Google Adwords.
	stmts, err := parser.NewParser(strings.NewReader(s.si.SrcQuery)).Parse()
	if err != nil {
		return err
	}
	if len(stmts) > 1 {
		return ErrMultipleQueries
	}
	s.p = stmts[0]

	return nil
}

// Close closes the statement.
func (s *Stmt) Close() error {
	return s.si.Close()
}

// NumInput returns the number of placeholder parameters.
func (s *Stmt) NumInput() int {
	return s.si.NumInput()
}

// Exec executes a query that doesn't return rows, such as an INSERT or UPDATE.
func (s *Stmt) Exec(args []driver.Value) (driver.Result, error) {
	// Binds all arguments.
	if err := s.Bind(args); err != nil {
		return nil, err
	}
	// Executes query.
	switch s.p.(type) {
	case parser.CreateViewStmt:
		return NewCreateViewStmt(s).Exec()
	}
	return s.si.Exec(args)
}

// Query sends request to Google Adwords API and retrieves its content.
func (s *Stmt) Query(args []driver.Value) (driver.Rows, error) {
	// Binds all arguments.
	if err := s.Bind(args); err != nil {
		return nil, err
	}
	// Executes query.
	switch s.p.(type) {
	case parser.DescribeStmt:
		return NewDescribeStmt(s).Query()
	case parser.ShowStmt:
		return NewShowStmt(s).Query()
	case parser.SelectStmt:
		return NewSelectStmt(s).Query()
	}
	return nil, ErrQuery
}

// Execer is an interface that may be implemented by a CreateViewStmt.
type Execer interface {
	Exec() (driver.Result, error)
}

// Queryer is an interface that should be implemented by a Stmt with rows as result.
type Queryer interface {
	Query() (driver.Rows, error)
}

// DescribeStmt represents a Describe statement.
type DescribeStmt struct {
	*Stmt
}

// NewDescribeStmt returns an instance of DescribeStmt.
// It implements Queryer interface.
func NewDescribeStmt(stmt *Stmt) Queryer {
	return &DescribeStmt{stmt}
}

// Query executes a Describe query, such as a DESC or DESCRIBE.
// It returns the properties of a table, filtered if requested on one field.
func (s *DescribeStmt) Query() (driver.Rows, error) {
	// Casts statement.
	stmt := s.p.(parser.DescribeStmt)

	// Checks it the table exists.
	tb, err := s.db.Table(stmt.SourceName())
	if err != nil {
		return nil, err
	}

	// formatBool returns a string representation of a boolean.
	var formatBool = func(ok bool) string {
		if ok {
			return "YES"
		}
		return "NO"
	}

	// formatKey returns PRI if the column is the primary key
	// or MUL if it is just an index.
	var formatKey = func(key, primary bool) string {
		switch {
		case key:
			return "MUL"
		case primary:
			return "PRI"
		}
		return ""
	}

	// fieldNames returns the columns names.
	var fieldNames = func(sizes []int) (cols []string) {
		size := len(sizes)
		if size == 0 {
			return
		}
		cols = make([]string, size)
		switch size {
		case 6:
			// Full mode
			cols[4] = fmtColumnName("Enum", sizes[4])
			cols[5] = fmtColumnName("Not_compatible_with", sizes[5])
			fallthrough
		case 4:
			// Default behavior
			cols[0] = fmtColumnName("Field", sizes[0])
			cols[1] = fmtColumnName("Type", sizes[1])
			cols[2] = fmtColumnName("Key", sizes[2])
			cols[3] = fmtColumnName("Supports_Zero_Impressions", sizes[3])
		}
		return cols
	}

	// fieldData returns the field properties.
	var aggregateData = func(fields []parser.DynamicField, pk string, full bool) (data [][]driver.Value, sizes []int) {
		size := len(fields)
		if size == 0 {
			return
		}
		colSize := 4
		if full {
			colSize = 6
		}
		sizes = make([]int, colSize)
		data = make([][]driver.Value, size)

		// Computes information for each requested columns.
		for i := 0; i < size; i++ {
			f := fields[i].(db.Field)
			data[i] = make([]driver.Value, colSize)
			switch colSize {
			case 6:
				// Full mode
				// > Enum list
				s := strings.Join(f.ValueList(), ", ")
				data[i][4] = s
				sizes[4] = maxLen(s, sizes[4])
				// > Not compatible columns
				u := strings.Join(f.NotCompatibleColumns(), ", ")
				data[i][5] = u
				sizes[5] = maxLen(u, sizes[5])
				fallthrough
			case 4:
				// Default behavior
				// > Column name
				n := f.Name()
				data[i][0] = n
				sizes[0] = maxLen(n, sizes[0])
				// > Type of field
				t := f.Kind()
				data[i][1] = t
				sizes[1] = maxLen(t, sizes[1])
				// > Key field
				k := formatKey(f.IsSegment(), f.Name() == pk)
				data[i][2] = k
				sizes[2] = maxLen(k, sizes[2])
				// > Zero impressions
				z := formatBool(f.SupportsZeroImpressions())
				data[i][3] = z
				sizes[3] = maxLen(z, sizes[3])
			}
		}

		return data, sizes
	}

	var colSize []int
	var data [][]driver.Value
	if cols := stmt.Columns(); len(cols) > 0 {
		// Gets properties on one specific column.
		fd, err := tb.Field(cols[0].Name())
		if err != nil {
			return nil, err
		}
		data, colSize = aggregateData([]parser.DynamicField{fd}, tb.AggregateFieldName(), stmt.FullMode())
	} else {
		// Gets properties of each columns of the table.
		data, colSize = aggregateData(tb.Columns(), tb.AggregateFieldName(), stmt.FullMode())
	}

	return &Rows{
		cols: fieldNames(colSize),
		data: data,
		size: len(data),
	}, nil
}

// CreateViewStmt represents a Create statement.
type CreateViewStmt struct {
	*Stmt
}

// NewCreateViewStmt returns an instance of CreateViewStmt.
// It implements Queryer interface.
func NewCreateViewStmt(stmt *Stmt) Execer {
	return &CreateViewStmt{stmt}
}

// Exec executes a Create View query.
func (s *CreateViewStmt) Exec() (driver.Result, error) {
	// Creates the view in database.
	// stmt, _ := s.p.(parser.CreateViewStmt)
	// if err := s.db.AddView(stmt); err != nil {
	// 	return nil, err
	// }
	/// @todo
	return &Result{}, nil
}

// SelectStmt represents a Select statement.
type SelectStmt struct {
	*Stmt
}

// NewSelectStmt returns an instance of SelectStmt.
// It implements Queryer interface.
func NewSelectStmt(stmt *Stmt) Queryer {
	return &SelectStmt{stmt}
}

// Hash builds a unique hash for this query and this Adwords ID.
func (s *SelectStmt) Hash() string {
	hash, _ := s.si.Hash()
	return hash + "-" + s.id
}

// Query executes a SELECT query
// It internally calls the Awql driver, aggregates, sorts and limits the results.
func (s *SelectStmt) Query() (driver.Rows, error) {
	// Casts statement.
	stmt := s.p.(*parser.SelectStatement)

	// Replaces the display name of columns by their names or alias if exist.
	var fieldNames = func(columns []parser.DynamicField, sizes []int) []string {
		cols := make([]string, len(columns))
		for i, c := range columns {
			if c.Alias() != "" {
				cols[i] = c.Alias()
			} else {
				cols[i] = c.Name()
			}
			// Formats the column name in order to reflect the maximum length of the column.
			cols[i] = fmtColumnName(cols[i], sizes[i])
		}
		return cols
	}

	// Adds more detail on each columns (kind, etc.).
	t, err := s.db.Table(stmt.SourceName())
	if err != nil {
		return nil, err
	}
	for i, c := range stmt.Fields {
		// Manages the special case of the SQL method COUNT.
		var m string
		var f db.Field
		if m, _ = c.UseFunction(); m == "COUNT" && c.Name() == "*" {
			f, err = t.Field(t.AggregateFieldName())
		} else {
			f, err = t.Field(c.Name())
		}
		if err != nil {
			return nil, err
		}
		// Casts to db.Column to merge it with statement properties.
		col := f.(db.Column)
		col.Method = m
		col.Label = c.Alias()
		col.Unique = c.Distinct()
		stmt.Fields[i] = col
	}

	// Keeps only accepted Adwords Awql grammar as query.
	s.si.SrcQuery = stmt.LegacyString()

	// Tries to retrieve data in cache.
	var records [][]string
	if records, err = s.fc.Get(s.Hash()); err != nil {
		// Requests the Adwords API without any args, binding already done.
		rows, err := s.si.Query(nil)
		if err != nil {
			return nil, err
		}
		records = rows.(*awql.Rows).Data
		// Saves the data in cache.
		go s.fc.Set(&cache.Item{Key: s.Hash(), Value: records})
	}

	// Aggregates rows by columns if needed.
	data, colSize, err := aggregateData(stmt, records)
	if err != nil {
		return nil, err
	}
	// Initialises the result set.
	size := len(data)
	if size == 0 {
		return nil, nil
	}
	rs := &Rows{
		cols: fieldNames(stmt.Columns(), colSize),
		data: data,
		size: size,
	}
	// Sorts rows by columns.
	if len(stmt.OrderList()) > 0 {
		rs.less = sortFuncs(stmt)
		rs.Sort()
	}
	// Limits the result set.
	if rc, ok := stmt.PageSize(); ok {
		rs.Limit(stmt.StartIndex(), rc)
	}
	return rs, nil
}

// aggregateData aggregates records as expected by the statement.
// Returns aggregated lines with maximum size of each column.
// An error occurred if we fail to parse records.
func aggregateData(stmt parser.SelectStmt, records [][]string) ([][]driver.Value, []int, error) {
	// autoValue trims prefixes `auto` and returns a cleaned string.
	// Also indicates with the second parameter, if it's a automatic value or not.
	var autoValued = func(s string) (v string, ok bool) {
		if ok = strings.HasPrefix(s, auto); !ok {
			// Not prefixed by auto keyword.
			v = s
			return
		}
		// Trims the prefix `auto: `
		if v = strings.TrimPrefix(s, autoValue); v == s {
			// Removes only `auto` as prefix
			v = strings.TrimPrefix(s, auto)
		}
		return
	}
	// lenFloat64 returns the length of the float by calculating the number of digit + point.
	var lenFloat64 = func(f Float64) (len int) {
		switch {
		case f.Float64 >= 1000000000000:
			len += 1
			fallthrough
		case f.Float64 >= 100000000000:
			len += 1
			fallthrough
		case f.Float64 >= 10000000000:
			len += 1
			fallthrough
		case f.Float64 >= 1000000000:
			len += 1
			fallthrough
		case f.Float64 >= 100000000:
			len += 1
			fallthrough
		case f.Float64 >= 10000000:
			len += 1
			fallthrough
		case f.Float64 >= 1000000:
			len += 1
			fallthrough
		case f.Float64 >= 100000:
			len += 1
			fallthrough
		case f.Float64 >= 10000:
			len += 1
			fallthrough
		case f.Float64 >= 1000:
			len += 1
			fallthrough
		case f.Float64 >= 100:
			len += 1
			fallthrough
		case f.Float64 >= 10:
			len += 1
			fallthrough
		default:
			len += 1
		}
		if f.Precision > 0 {
			// Manages `.01`
			len += f.Precision + 1
		}
		return
	}
	// parsePercentNullFloat64 parses a string and returns it as double that can be a percentage.
	var parsePercentNullFloat64 = func(s string) (d PercentNullFloat64, err error) {
		if s == doubleDash {
			// Not set, null value.
			return
		}
		if d.Percent = strings.HasSuffix(s, "%"); d.Percent {
			s = strings.TrimSuffix(s, "%")
		}
		switch s {
		case almost10:
			// Sometimes, when it's less than 10, Google displays "< 10%".
			d.NullFloat64.Float64 = 9.999
			d.NullFloat64.Valid = true
			d.Almost = true
		case almost90:
			// Or "> 90%" when it is the opposite.
			d.NullFloat64.Float64 = 90.001
			d.NullFloat64.Valid = true
			d.Almost = true
		default:
			if d.NullFloat64.Float64, err = strconv.ParseFloat(s, 64); err == nil {
				d.NullFloat64.Valid = true
			}
		}
		return
	}
	// parseNullFloat64 parses a string and returns it as a nullable double.
	var parseNullFloat64 = func(s string) (d sql.NullFloat64, err error) {
		if s == doubleDash {
			// Not set, null value.
			return
		}
		if d.Float64, err = strconv.ParseFloat(s, 64); err == nil {
			d.Valid = true
		}
		return
	}
	// parseAutoNullInt64 parses a string and returns it as integer.
	var parseAutoNullInt64 = func(s string) (d AutoNullInt64, err error) {
		if s == doubleDash {
			// Not set, null value.
			return
		}
		if s, d.Auto = autoValued(s); s == "" {
			// Not set, null and automatic value.
			return
		}
		if d.NullInt64.Int64, err = strconv.ParseInt(s, 10, 64); err == nil {
			d.NullInt64.Valid = true
		}
		return
	}
	// parseTime parses a string and returns its time representation by using the layout.
	var parseTime = func(layout, s string) (Time, error) {
		if s == doubleDash {
			// Not set, null value.
			return Time{Time: time.Time{}}, nil
		}
		t, err := time.Parse(layout, s)

		return Time{Time: t, Layout: layout}, err
	}
	// parseString parses a string and returns a NullString.
	var parseString = func(s string) (NullString, error) {
		if s == doubleDash {
			return NullString{}, nil
		}
		return NullString{Valid: true, String: s}, nil
	}
	// cast gives the type equivalences of API adwords type of data.
	var cast = func(s, kind string) (driver.Value, error) {
		switch strings.ToUpper(kind) {
		case "BID", "INT", "INTEGER", "LONG", "MONEY":
			return parseAutoNullInt64(s)
		case "DOUBLE":
			return parsePercentNullFloat64(s)
		case "DATE":
			return parseTime("2006-01-02", s)
		case "DATETIME":
			return parseTime("2006/01/02 15:04:05", s)
		}
		return parseString(s)
	}
	// hash returns a numeric hash for the given string.
	var hash = func(s string) uint64 {
		h := fnv.New64a()
		h.Write([]byte(s))
		return h.Sum64()
	}
	// useAggregate returns true if at least one columns uses a aggregate function.
	var useAggregate = func(stmt parser.SelectStmt) bool {
		for _, c := range stmt.Columns() {
			if c.Distinct() {
				return true
			}
			if _, use := c.UseFunction(); use {
				return true
			}
		}
		return false
	}
	distinctLine := useAggregate(stmt)

	// Bounds
	groupSize := len(stmt.GroupList())
	columnSize := len(stmt.Columns())

	// Builds a map with group values as key.
	var data map[string][]driver.Value
	data = make(map[string][]driver.Value)
	cs := make([]int, columnSize)
	for p, f := range records {
		// Picks the aggregate values.
		var group []uint64
		if groupSize > 0 {
			for _, gb := range stmt.GroupList() {
				group = append(group, hash(f[gb.Position()-1]))
			}
		} else if !distinctLine {
			group = append(group, uint64(p))
		}
		key := fmt.Sprint(group)

		// Converts string slice of the row as expected by SQL driver.
		row := make([]driver.Value, columnSize)
		for i, c := range stmt.Columns() {
			if method, ok := c.UseFunction(); ok {
				// Retrieves the aggregate value if already set.
				var v Float64
				if r, ok := data[key]; ok {
					v = r[i].(Float64)
				}
				if method == "COUNT" {
					// Increments the counter.
					v.Float64++
					// Calculates the length of the column.
					cs[i] = lenFloat64(v)
					row[i] = v
					continue
				}
				// Casts to float the current column's value.
				cv, err := parseNullFloat64(f[i])
				if err != nil {
					return nil, nil, err
				}
				if !cv.Valid {
					// Nil value, skip it.
					row[i] = v
					continue
				}
				// Applies the aggregate method on it valid value.
				switch method {
				case "AVG":
					// ((previous average x number of elements seen) + current value) /
					// current number of elements
					fi := float64(i)
					v.Float64 = ((v.Float64 * fi) + cv.Float64) / (fi + 1)
				case "MAX":
					if v.Float64 < cv.Float64 {
						v.Float64 = cv.Float64
					}
				case "MIN":
					if v.Float64 > cv.Float64 {
						v.Float64 = cv.Float64
					}
				case "SUM":
					v.Float64 += cv.Float64
				default:
					return nil, nil, NewXError("unknown method", method)
				}
				// Determines the precision to use in order to round it.
				if strings.ToUpper(c.(db.Field).Kind()) == "DOUBLE" {
					v.Precision = 2
				}
				// Calculates the size of the column in order to keep its max length.
				cs[i] = lenFloat64(v)
				row[i] = v
			} else {
				v, err := cast(f[i], c.(db.Field).Kind())
				if err != nil {
					return nil, nil, err
				}
				// Calculates the size of the column in order to keep its max length.
				cs[i] = maxLen(f[i], cs[i])
				row[i] = v
			}
		}
		data[key] = row
	}

	// Builds the result set.
	rs := make([][]driver.Value, len(data))
	var i int
	for _, r := range data {
		rs[i] = r
		i++
	}
	return rs, cs, nil
}

// lessFunc
type lessFunc func(p1, p2 []driver.Value) bool

func sortFuncs(stmt parser.SelectStmt) (orders []lessFunc) {
	orders = make([]lessFunc, len(stmt.OrderList()))
	if len(orders) == 0 {
		return
	}

	for i, o := range stmt.OrderList() {
		pos := o.Position() - 1
		orders[i] = func(p1, p2 []driver.Value) bool {
			switch p1[pos].(type) {
			case AutoNullInt64:
				v1, v2 := p1[pos].(AutoNullInt64), p2[pos].(AutoNullInt64)
				if o.SortDescending() {
					return v1.NullInt64.Int64 > v2.NullInt64.Int64
				}
				return v1.NullInt64.Int64 < v2.NullInt64.Int64
			case PercentNullFloat64:
				v1, v2 := p1[pos].(PercentNullFloat64), p2[pos].(PercentNullFloat64)
				if o.SortDescending() {
					return v1.NullFloat64.Float64 > v2.NullFloat64.Float64
				}
				return v1.NullFloat64.Float64 < v2.NullFloat64.Float64
			case Float64:
				v1, v2 := p1[pos].(Float64), p2[pos].(Float64)
				if o.SortDescending() {
					return v1.Float64 > v2.Float64
				}
				return v1.Float64 < v2.Float64
			case Time:
				v1, v2 := p1[pos].(Time), p2[pos].(Time)
				if o.SortDescending() {
					return !v1.Time.Before(v2.Time)
				}
				return v1.Time.Before(v2.Time)
			case NullString:
				v1, v2 := p1[pos].(NullString), p2[pos].(NullString)
				if o.SortDescending() {
					return v1.String > v2.String
				}
				return v1.String < v2.String
			default:
				// Type of value do not managed by sort order.
				return false
			}
		}
	}
	return
}

// ShowStmt represents a Show statement.
type ShowStmt struct {
	*Stmt
}

// NewShowStmt returns an instance of ShowStmt.
// It implements Queryer interface.
func NewShowStmt(stmt *Stmt) Queryer {
	return &ShowStmt{stmt}
}

// Query executes a SHOW query
// It returns a list of a table, filtered if requested with the like or with clause.
func (s *ShowStmt) Query() (driver.Rows, error) {
	// Casts statement.
	stmt := s.p.(parser.ShowStmt)

	// fieldNames returns the columns names.
	var fieldNames = func(version string, sizes []int) (cols []string) {
		nbCol := len(sizes)
		if nbCol == 0 {
			return
		}
		cols = make([]string, nbCol)
		switch nbCol {
		case 2:
			cols[1] = fmtColumnName("Table_type", sizes[1])
			fallthrough
		case 1:
			cols[0] = fmtColumnName("Tables_in_"+version, sizes[0])
		}
		return cols
	}

	var tables []db.DataTable
	if p, ok := stmt.LikePattern(); ok {
		// Lists the tables using the like clause.
		switch {
		case p.Contains != "":
			tables = s.db.TablesContains(p.Contains)
		case p.Equal != "":
			if tb, err := s.db.Table(p.Equal); err == nil {
				tables = []db.DataTable{tb}
			}
		case p.Prefix != "":
			tables = s.db.TablesPrefixedBy(p.Prefix)
		case p.Suffix != "":
			tables = s.db.TablesSuffixedBy(p.Suffix)
		}
	} else if column, ok := stmt.WithFieldName(); ok {
		// Lists the tables using the with clause.
		tables = s.db.TablesWithColumn(column)
	} else {
		// Lists all tables.
		tables, _ = s.db.Tables()
	}

	size := len(tables)
	if size == 0 {
		return &Rows{}, nil
	}
	nbCol := 1
	if stmt.FullMode() {
		nbCol++
	}
	cs := make([]int, nbCol)
	rs := make([][]driver.Value, size)
	for i := 0; i < size; i++ {
		rs[i] = make([]driver.Value, nbCol)
		switch nbCol {
		case 2:
			var kind string
			if tables[i].IsView() {
				kind = "VIEW"
			} else {
				kind = "BASE TABLE"
			}
			rs[i][1] = kind
			cs[1] = maxLen(kind, cs[1])
			fallthrough
		case 1:
			rs[i][0] = tables[i].SourceName()
			cs[0] = maxLen(tables[i].SourceName(), cs[0])
		}
	}
	return &Rows{
		cols: fieldNames(s.db.Version, cs),
		data: rs,
		size: size,
	}, nil
}

// maxLen returns the length in runes of the string, only if it is more bigger than minLen.
func maxLen(name string, minLen int) (len int) {
	len = utf8.RuneCountInString(name)
	if len < minLen {
		len = minLen
	}
	return
}

// fmtColumnName returns the name of the column formatted as expected to display it.
func fmtColumnName(name string, minLen int) string {
	return fmt.Sprintf("%-"+strconv.Itoa(maxLen(name, minLen))+"v", name)
}

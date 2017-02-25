package driver

import (
	"database/sql/driver"
	"fmt"
	"hash/fnv"
	"strconv"
	"strings"
	"time"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
	parser "github.com/rvflash/awql-parser"
	cache "github.com/rvflash/csv-cache"
)

// Google uses ' --' instead of an empty string to symbolize the fact that the field was never set
var doubleDash = " --"

// Stmt is a prepared statement.
type Stmt struct {
	si *awql.Stmt
	db *db.Database
	fc *cache.Cache
	id string
	p  parser.Stmt
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

	// fieldCols returns the columns names.
	var fieldCols = func(full bool) []string {
		cols := []string{"Field", "Type", "Key", "Supports_Zero_Impressions"}
		if full {
			cols = append(cols, "Enum", "Not_compatible_with")
		}
		return cols
	}
	names := fieldCols(stmt.FullMode())

	// fieldData returns the field properties.
	var fieldData = func(f db.Field, pk string, full bool) []driver.Value {
		isPk := false
		if f.Name() == pk {
			isPk = true
		}
		data := []driver.Value{
			f.Name(), f.Kind(), formatKey(f.IsSegment(), isPk),
			formatBool(f.SupportsZeroImpressions()),
		}
		if full {
			data = append(
				data,
				strings.Join(f.ValueList(), ", "),
				strings.Join(f.NotCompatibleColumns(), ", "),
			)
		}
		return data
	}

	// fieldKind returns for each column, their kind.
	var fieldKind = func(cols []string) []string {
		kind := make([]string, len(cols))
		for i, c := range cols {
			switch c {
			case "Supports_Zero_Impressions", "Enum":
				kind[i] = "ENUM"
			case "Not_compatible_with":
				kind[i] = "LIST"
			default:
				kind[i] = "STRING"
			}
		}
		return kind
	}

	// Filters on one column.
	if cols := stmt.Columns(); len(cols) > 0 {
		fd, err := tb.Field(cols[0].Name())
		if err != nil {
			return nil, err
		}
		return &Rows{
			cols: names,
			kind: fieldKind(names),
			data: [][]driver.Value{fieldData(fd, tb.AggregateFieldName(), stmt.FullMode())},
			size: 1,
		}, nil
	}

	// Gets properties of each columns of the table.
	cols := tb.Columns()
	size := len(cols)
	rows := make([][]driver.Value, size)
	for p, fd := range cols {
		rows[p] = fieldData(fd.(db.Field), tb.AggregateFieldName(), stmt.FullMode())
	}

	return &Rows{
		cols: names,
		kind: fieldKind(names),
		data: rows,
		size: size,
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

// Query executes a Create View query.
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

// Query executes a SELECT query
// It internally calls the Awql driver, aggregates, sorts and limits the results.
func (s *SelectStmt) Query() (driver.Rows, error) {
	// Casts statement.
	stmt := s.p.(*parser.SelectStatement)

	// Replaces the display name of columns by their names or alias if exist.
	var fieldCols = func(columns []parser.DynamicField) []string {
		cols := make([]string, len(columns))
		for p, c := range columns {
			if c.Alias() != "" {
				cols[p] = c.Alias()
			} else {
				cols[p] = c.Name()
			}
		}
		return cols
	}

	// Adds more detail on each columns (kind, etc.).
	t, err := s.db.Table(stmt.SourceName())
	if err != nil {
		return nil, err
	}
	kind := make([]string, len(stmt.Fields))
	for i, c := range stmt.Fields {
		// Converts parser.DynamicField to db.Field.
		f, err := t.Field(c.Name())
		if err != nil {
			return nil, err
		}
		stmt.Fields[i] = f

		// Gets data's kind to display.
		if method, use := f.UseFunction(); use {
			if method == "COUNT" {
				kind[i] = "DOUBLE_TO_INT"
			} else {
				kind[i] = "DOUBLE"
			}
		} else {
			kind[i] = strings.ToUpper(f.Kind())
		}
	}

	// Keeps only accepted Adwords Awql grammar as query.
	s.si.SrcQuery = stmt.LegacyString()

	// Builds a unique hash for this query / Adwords ID.
	hash, _ := s.si.Hash()
	hash += "-" + s.id

	// Tries to retrieve data in cache.
	var records [][]string
	if records, err = s.fc.Get(hash); err != nil {
		// Requests the Adwords API without any args, binding already done.
		rows, err := s.si.Query(nil)
		if err != nil {
			return nil, err
		}
		records = rows.(*awql.Rows).Data
		// Saves the data in cache.
		go s.fc.Set(&cache.Item{Key: hash, Value: records})
	}

	// Aggregates rows by columns if needed.
	data, err := aggregateData(stmt, records)
	if err != nil {
		return nil, err
	}
	// Initialises the result set.
	rs := &Rows{
		cols: fieldCols(stmt.Columns()),
		data: data,
		kind: kind,
		size: len(data),
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

// aggregateData
func aggregateData(stmt parser.SelectStmt, records [][]string) ([][]driver.Value, error) {
	// parseTime parses a string and returns its time representation by using the layout.
	var parseTime = func(layout, s string) (time.Time, error) {
		if s == doubleDash {
			return time.Time{}, nil
		}
		return time.Parse(layout, s)
	}
	// cast gives the type equivalences of API adwords type of data.
	var cast = func(s, kind string) (driver.Value, error) {
		switch strings.ToUpper(kind) {
		case "INT", "INTEGER", "LONG", "MONEY":
			return strconv.ParseInt(s, 10, 64)
		case "DOUBLE":
			return strconv.ParseFloat(s, 64)
		case "DATE":
			return parseTime("2006-01-02", s)
		case "DATETIME":
			return parseTime("2006/01/02 15:04:05", s)
		}
		return s, nil
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
				var v, cv float64
				if r, ok := data[key]; ok {
					v = r[i].(float64)
				}
				if method == "COUNT" {
					v++
				} else {
					// Casts to float the column value.
					var err error
					cv, err = strconv.ParseFloat(f[i], 64)
					if err != nil {
						return nil, err
					}
					// Applies the method on it.
					switch method {
					case "AVG":
						// ((previous average x number of elements seen) + current value) / current number of elements
						fi := float64(i)
						v = ((v * fi) + cv) / (fi + 1)
					case "MAX":
						if v < cv {
							v = cv
						}
					case "MIN":
						if v > cv {
							v = cv
						}
					case "SUM":
						v += cv
					default:
						return nil, fmt.Errorf("unknown method named %s", method)
					}
				}
				row[i] = v
			} else {
				v, err := cast(f[i], c.(db.Field).Kind())
				if err != nil {
					return nil, err
				}
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
	return rs, nil
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
		f := stmt.Columns()[pos].(db.Field)
		orders[i] = func(p1, p2 []driver.Value) bool {
			// Casts values to compare it.
			var kind string
			if _, use := f.UseFunction(); use {
				kind = "DOUBLE"
			} else {
				// Gets raw type from Google API. Manages `Long` or `long`.
				kind = strings.ToUpper(f.Kind())
			}
			switch kind {
			case "INT", "INTEGER", "LONG", "MONEY":
				v1, v2 := p1[pos].(int64), p2[pos].(int64)
				if o.SortDescending() {
					return v1 > v2
				}
				return v1 < v2
			case "DOUBLE":
				v1, v2 := p1[pos].(float64), p2[pos].(float64)
				if o.SortDescending() {
					return v1 > v2
				}
				return v1 < v2
			case "DATE", "DATETIME":
				v1, v2 := p1[pos].(time.Time), p2[pos].(time.Time)
				if o.SortDescending() {
					return !v1.Before(v2)
				}
				return v1.Before(v2)
			default:
				v1, v2 := p1[pos].(string), p2[pos].(string)
				if o.SortDescending() {
					return v1 > v2
				}
				return v1 < v2
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

	// fieldCols returns the columns names.
	var fieldCols = func(version string, full bool) []string {
		cols := []string{"Tables_in_" + version}
		if full {
			cols = append(cols, "Table_type")
		}
		return cols
	}
	// fieldData returns the field properties.
	var fieldData = func(t db.DataTable, full bool) []driver.Value {
		data := []driver.Value{t.SourceName()}
		if full {
			kind := "BASE TABLE"
			if t.IsView() {
				kind = "VIEW"
			}
			data = append(data, kind)
		}
		return data
	}
	// fieldKind returns for each column, their kind.
	var fieldKind = func(cols []string) []string {
		kind := make([]string, len(cols))
		for i, c := range cols {
			switch c {
			case "Table_type":
				kind[i] = "ENUM"
			default:
				kind[i] = "STRING"
			}
		}
		return kind
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
	rows := make([][]driver.Value, size)
	for i := 0; i < size; i++ {
		rows[i] = fieldData(tables[i], stmt.FullMode())
	}
	cols := fieldCols(s.db.Version, stmt.FullMode())
	return &Rows{
		cols: cols,
		kind: fieldKind(cols),
		data: rows,
		size: size,
	}, nil
}

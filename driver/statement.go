package driver

import (
	"database/sql/driver"
	"strings"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
	parser "github.com/rvflash/awql-parser"
)

// Execer is an interface that may be implemented by a Stmt.
type Execer interface {
	Exec() (driver.Result, error)
}

// Queryer is an interface that should be implemented by a Stmt.
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

	// fieldData returns the field properties.
	var fieldData = func(f db.Field, pk string, full bool) []string {
		isPk := false
		if f.Name() == pk {
			isPk = true
		}
		data := []string{
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

	// Filters on one column.
	if cols := stmt.Columns(); len(cols) > 0 {
		fd, err := tb.Field(cols[0].Name())
		if err != nil {
			return nil, err
		}
		return &Rows{
			cols: fieldCols(stmt.FullMode()),
			data: &awql.Rows{
				Size: 1,
				Data: [][]string{fieldData(fd, tb.AggregateFieldName(), stmt.FullMode())},
			},
		}, nil
	}

	// Gets properties of each columns of the table.
	cols := tb.Columns()
	size := len(cols)
	rows := make([][]string, size)
	for p, fd := range cols {
		rows[p] = fieldData(fd.(db.Field), tb.AggregateFieldName(), stmt.FullMode())
	}

	return &Rows{
		cols: fieldCols(stmt.FullMode()),
		data: &awql.Rows{Size: uint(size), Data: rows},
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
	stmt := s.p.(parser.SelectStmt)

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

	// Keeps only accepted Adwords Awql grammar as query.
	s.si.SrcQuery = stmt.String()

	// Requests the Adwords API without any args, binding already done.
	rows, err := s.si.Query(nil)
	if err != nil {
		return nil, err
	}

	// Initialises the result set.
	rs := &Rows{
		cols: fieldCols(stmt.Columns()),
		data: rows.(*awql.Rows),
	}
	// @todo
	// Aggregates rows by columns.
	rs.Aggregate(stmt.Columns(), stmt.GroupList())

	// Sorts rows by columns.
	rs.Sort(stmt.OrderList())

	// Limits the result set.
	if rc, ok := stmt.PageSize(); ok {
		rs.Limit(stmt.StartIndex(), rc)
	}

	return rs, nil
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

	var fieldCols = func(version string, full bool) []string {
		cols := []string{"Tables_in_" + version}
		if full {
			cols = append(cols, "Table_type")
		}
		return cols
	}
	var fieldData = func(t db.DataTable, full bool) []string {
		data := []string{t.SourceName()}
		if full {
			kind := "BASE TABLE"
			if t.IsView() {
				kind = "VIEW"
			}
			data = append(data, kind)
		}
		return data
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
	rows := make([][]string, size)
	for i := 0; i < size; i++ {
		rows[i] = fieldData(tables[i], stmt.FullMode())
	}

	return &Rows{
		cols: fieldCols(s.db.Version, stmt.FullMode()),
		data: &awql.Rows{Size: uint(size), Data: rows},
	}, nil
}

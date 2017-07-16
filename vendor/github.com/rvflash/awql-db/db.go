package awqldb

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/rvflash/awql-db/internal/schema"

	awql "github.com/rvflash/awql-parser"
	"gopkg.in/yaml.v2"
)

// Error messages.
var (
	ErrVersion         = NewDatabaseError("version not supported")
	ErrNoTable         = NewDatabaseError("no table")
	ErrTableExists     = NewDatabaseError("table already exists")
	ErrLoadTables      = NewDatabaseError("tables")
	ErrLoadViews       = NewDatabaseError("views")
	ErrLoadColumns     = NewDatabaseError("columns")
	ErrMismatchColumns = NewDatabaseError("columns mismatch")
	ErrUnknownTable    = NewDatabaseError("unknown table")
	ErrUnknownColumn   = NewDatabaseError("unknown column")
)

// Database represents the database.
type Database struct {
	fd     map[string][]DataTable
	tb, vw []DataTable
	ready  bool
	Version,
	dir, vwFile string
}

// Open returns a new connexion to the Adwords database.
// @see https://github.com/rvflash/awql-db#data-source-name for how
// the DSN string is formatted
func Open(dsn string) (*Database, error) {
	// parseDsn extracts from the data source name, the database directory,
	// the API version and an optional boolean to disable the database loading.
	var parseDsn = func(s string) (dir, vwFile, version string, noOp bool) {
		dsn := strings.Split(s, "|")
		switch len(dsn) {
		case 3:
			vwFile = dsn[2]
			fallthrough
		case 2:
			dir = dsn[1]
			fallthrough
		case 1:
			opt := strings.Split(dsn[0], ":")
			if len(opt) == 2 {
				noOp, _ = strconv.ParseBool(opt[1])
			}
			version = opt[0]
		}
		return
	}

	var noOp bool
	db := &Database{}
	db.dir, db.vwFile, db.Version, noOp = parseDsn(dsn)

	// Uses the default directory if the path is empty.
	if db.dir == "" {
		db.dir = "./internal/schema/src"
	}
	// Uses the default view file if the path is empty.
	if db.vwFile == "" {
		db.vwFile = filepath.Join(db.dir, "views.yml")
	}
	if db.Version == "" {
		// Set the latest API version if it is undefined.
		vs := db.SupportedVersions()
		sort.Strings(vs)
		db.Version = vs[len(vs)-1]
	}
	// Checks if it's a valid API version.
	if !db.HasVersion(db.Version) {
		return db, ErrVersion
	}
	if !noOp {
		if err := db.Load(); err != nil {
			return db, err
		}
	}
	return db, nil
}

// IsSupported returns true if the version is supported.
func (d *Database) HasVersion(version string) bool {
	if version == "" {
		return false
	}
	for _, v := range d.SupportedVersions() {
		if v == version {
			return true
		}
	}
	return false
}

// SupportedVersions returns the list of Adwords API versions supported.
func (d *Database) SupportedVersions() (versions []string) {
	for _, f := range schema.AssetNames() {
		versions = append(versions, strings.Split(f, "/")[1])
	}
	return
}

// AddView creates and adds a view in the database.
// Writes it to config file and adds it to current database.
// It return on error if the view can not be saved.
func (d *Database) AddView(stmt awql.CreateViewStmt) error {
	// Checks if the view already exists.
	v, err := d.newView(stmt)
	if err != nil {
		return err
	}

	// Updates the views configuration file.
	views := make([]DataTable, len(d.vw))
	copy(views, d.vw)
	var exists bool
	for i, ov := range d.vw {
		// View already exists, so replace it!
		if exists = ov.SourceName() == v.SourceName(); exists {
			d.vw[i] = v
			break
		}
	}
	if !exists {
		views = append(views, v)
	}

	// Stringify the views.
	s := "views:" + newline
	for _, v := range views {
		s += v.String()
	}
	if err := ioutil.WriteFile(d.vwFile, []byte(s), 0644); err != nil {
		return err
	}
	d.vw = views

	return nil
}

// ColumnNamesPrefixedBy returns a list of column names prefixed by its pattern.
// If the pattern is empty, all column names are returned.
func (d *Database) ColumnNamesPrefixedBy(pattern string) (columns []string) {
	for s := range d.fd {
		if strings.HasPrefix(s, pattern) {
			columns = append(columns, s)
		}
	}
	return
}

// Load loads all dependencies of the database.
func (d *Database) Load() error {
	if d.ready {
		return nil
	}
	if err := d.loadReports(); err != nil {
		return ErrLoadTables
	}
	if err := d.loadViews(); err != nil {
		return ErrLoadViews
	}
	if err := d.buildColumnsIndex(); err != nil {
		return ErrLoadColumns
	}
	d.ready = true

	return nil
}

// Table returns the table by its name or an error if it not exists.
func (d *Database) Table(table string) (DataTable, error) {
	for _, t := range d.tb {
		if t.SourceName() == table {
			return t, nil
		}
	}
	// Search in Views
	for _, v := range d.vw {
		if v.SourceName() == table {
			return v, nil
		}
	}
	return nil, ErrUnknownTable
}

// Tables returns the list of all tables or a error if there is none.
func (d *Database) Tables() ([]DataTable, error) {
	if d.ready {
		if len(d.vw) > 0 {
			return append(d.tb, d.vw...), nil
		}
		return d.tb, nil
	}
	return nil, ErrNoTable
}

// TablesContains returns the list of tables prefixed by this pattern.
func (d *Database) TablesContains(pattern string) (tables []DataTable) {
	// Search in all reports.
	for _, t := range d.tb {
		if strings.Contains(t.SourceName(), pattern) {
			tables = append(tables, t)
		}
	}
	// Search in Views
	for _, v := range d.vw {
		if strings.Contains(v.SourceName(), pattern) {
			tables = append(tables, v)
		}
	}
	return tables
}

// TablesPrefixedBy returns the list of tables prefixed by this pattern.
func (d *Database) TablesPrefixedBy(pattern string) (tables []DataTable) {
	// Search in all reports.
	for _, t := range d.tb {
		if strings.HasPrefix(t.SourceName(), pattern) {
			tables = append(tables, t)
		}
	}
	// Search in Views
	for _, v := range d.vw {
		if strings.HasPrefix(v.SourceName(), pattern) {
			tables = append(tables, v)
		}
	}
	return tables
}

// TablesSuffixedBy returns the list of tables suffixed by this pattern.
func (d *Database) TablesSuffixedBy(pattern string) (tables []DataTable) {
	// Search in all reports.
	for _, t := range d.tb {
		if strings.HasSuffix(t.SourceName(), pattern) {
			tables = append(tables, t)
		}
	}
	// Search in Views
	for _, v := range d.vw {
		if strings.HasSuffix(v.SourceName(), pattern) {
			tables = append(tables, v)
		}
	}
	return tables
}

// TablesWithColumn returns the list of tables using this column.
func (d *Database) TablesWithColumn(column string) []DataTable {
	return d.fd[column]
}

// buildColumnsIndex lists for each column the tables using it.
func (d *Database) buildColumnsIndex() error {
	if len(d.tb) == 0 {
		return ErrNoTable
	}

	// Create an index by column.
	d.fd = make(map[string][]DataTable)

	// Indexes the reports.
	var name string
	for _, t := range d.tb {
		for _, c := range t.Columns() {
			name = c.Name()
			d.fd[name] = append(d.fd[name], t)
		}
	}
	// Do the same with views.
	for _, v := range d.vw {
		for _, c := range v.Columns() {
			if c.Alias() != "" {
				name = c.Alias()
			} else {
				name = c.Name()
			}
			d.fd[name] = append(d.fd[name], v)
		}
	}

	return nil
}

// loadReports loads all report table and returns it as Database or error.
func (d *Database) loadReports() error {
	// Gets the static content of the Yaml configuration file.
	ymlFile, err := schema.Asset(fmt.Sprintf("src/%s/reports.yml", d.Version))
	if err != nil {
		return err
	}
	// Reports represents all reports from the configuration file.
	type Reports struct {
		Reports []Table `yaml:"reports"`
	}
	var r Reports
	if err := yaml.Unmarshal(ymlFile, &r); err != nil {
		return err
	}
	// Converts slice of Table in slice of awql.CreateViewStmt.
	d.tb = make([]DataTable, len(r.Reports))
	for i := range r.Reports {
		d.tb[i] = r.Reports[i]
	}

	return nil
}

// loadReports loads all report table and returns it as Database or error.
func (d *Database) loadViews() error {
	// Validates the path.
	p, err := filepath.Abs(d.vwFile)
	if err != nil {
		return err
	}
	// Gets reference in Yaml format.
	ymlFile, err := ioutil.ReadFile(p)
	if err != nil {
		return nil
	}
	// Views represents all views from the configuration file.
	type Views struct {
		Views []Table
	}
	var v Views
	if err := yaml.Unmarshal(ymlFile, &v); err != nil {
		return err
	}
	// Converts slice of Table in slice of awql.CreateViewStmt.
	d.vw = make([]DataTable, len(v.Views))
	for i, w := range v.Views {
		// Adds table properties on each view.
		t, err := d.Table(w.View.Name)
		if err != nil {
			return err
		}

		// Merges column properties of the view with these of the table.
		var fields []Column
		for _, c := range w.Cols {
			f, err := t.Field(c.Head)
			if err != nil {
				return nil
			}
			field := f.(Column)
			field.Label = c.Alias()
			fields = append(fields, field)
		}
		v.Views[i].Cols = fields

		// Finally, save it.
		d.vw[i] = v.Views[i]
	}

	return nil
}

// newView returns a new instance of Table for a view or an error.
func (d *Database) newView(stmt awql.CreateViewStmt) (DataTable, error) {
	// Checks if the new table already exists.
	if t, err := d.Table(stmt.SourceName()); err == nil {
		if !stmt.ReplaceMode() || !t.IsView() {
			return nil, ErrTableExists
		}
	}

	// Checks if table source exists. Gets its primary key.
	src, err := d.Table(stmt.SourceQuery().SourceName())
	if err != nil {
		return nil, err
	}
	t := src.(Table)

	// Prepares the view.
	view := Table{
		Name:       stmt.SourceName(),
		PrimaryKey: t.PrimaryKey,
	}

	// Prepares the data source.
	data := View{
		Name:       t.Name,
		PrimaryKey: view.PrimaryKey,
	}

	// Manages columns.
	cols, cnames := stmt.SourceQuery().Columns(), stmt.Columns()
	size, csize := len(cols), len(cnames)
	data.Cols = make([]Column, size)
	for i := 0; i < size; i++ {
		var alias awql.DynamicField
		if i >= csize {
			alias = cols[i]
		} else {
			alias = cnames[i]
		}
		col, err := t.newColumn(cols[i], alias)
		if err != nil {
			return nil, err
		}
		data.Cols[i] = col
	}

	// Manages where clause.
	where := stmt.SourceQuery().ConditionList()
	if size := len(where); size > 0 {
		data.Where = make([]Condition, size)
		for i := 0; i < size; i++ {
			data.Where[i] = newCondition(where[i])
		}
	}

	// Manages during clause.
	data.During = stmt.SourceQuery().DuringList()

	// Manages group by clause.
	group := stmt.SourceQuery().GroupList()
	if size := len(group); size > 0 {
		data.GroupBy = make([]GroupBy, size)
		for i := 0; i < size; i++ {
			data.GroupBy[i] = newGroupBy(group[i])
		}
	}

	// Manages order by clause.
	order := stmt.SourceQuery().OrderList()
	if size := len(order); size > 0 {
		data.OrderBy = make([]Order, size)
		for i := 0; i < size; i++ {
			data.OrderBy[i] = newOrderBy(order[i])
		}
	}

	// Manages limit clause.
	if row, ok := stmt.SourceQuery().PageSize(); ok {
		data.Limit.Offset = stmt.SourceQuery().StartIndex()
		data.Limit.RowCount = row
	}

	// Copy columns of the data source, merged with view's columns names, on the view.
	view.Cols = make([]Column, size)
	copy(view.Cols, data.Cols)

	// Finally adds the table source.
	view.View = data

	return view, nil
}

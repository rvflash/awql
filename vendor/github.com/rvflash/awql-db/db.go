package awql_db

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"

	awql "github.com/rvflash/awql-parser"
	"gopkg.in/yaml.v2"
)

// Environment.
const (
	dbDir       = "./src"
	reportsPath = dbDir + "/%s/reports.yml"
	viewsPath   = dbDir + "/views.yml"
)

// Error messages.
var (
	ErrNoTable         = NewDatabaseError("no table")
	ErrTableExists     = NewDatabaseError("table already exists")
	ErrLoadTables      = NewDatabaseError("tables")
	ErrLoadViews       = NewDatabaseError("views")
	ErrLoadColumns     = NewDatabaseError("columns")
	ErrMismatchColumns = NewDatabaseError("columns mismatch")
	ErrUnknownTable    = NewDatabaseError("unknown table")
	ErrUnknownColumn   = NewDatabaseError("unknown column")
)

// IsSupported returns true if the version is supported.
func IsSupported(version string) bool {
	if version == "" {
		return false
	}
	for _, v := range SupportedVersions() {
		if v == version {
			return true
		}
	}
	return false
}

// SupportedVersions returns the list of Adwords API versions supported.
func SupportedVersions() (versions []string) {
	files, err := ioutil.ReadDir(dbDir)
	if err != nil {
		return
	}
	for _, f := range files {
		if f.IsDir() {
			versions = append(versions, f.Name())
		}
	}
	return
}

// Database represents the database.
type Database struct {
	Version       string
	fd            map[string][]DataTable
	tb, vw        []DataTable
	ready         bool
	dir, viewFile string
}

// NewParser returns a new instance of Database.
func NewDb(version, src string) *Database {
	return &Database{Version: version, dir: src, viewFile: viewsPath}
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
		if exists := ov.SourceName() == v.SourceName(); exists {
			// View already exists, replace it!
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
	if err := ioutil.WriteFile(d.viewFile, []byte(s), 0644); err != nil {
		return err
	}
	d.vw = views

	return nil
}

// Load loads all dependencies of the database.
func (d *Database) Load() error {
	if d.ready {
		return nil
	}
	if err := d.loadReports(); err != nil {
		return ErrLoadTables
	}
	if err := d.loadViewsAndIndexes(); err != nil {
		return err
	}
	d.ready = true

	return nil
}

// Report returns the table by its name or an error if it not exists.
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

// Reports returns the list of all tables or a error if there is none.
func (d *Database) Tables() ([]DataTable, error) {
	if d.ready {
		if len(d.vw) > 0 {
			return append(d.tb, d.vw...), nil
		}
		return d.tb, nil
	}
	return nil, ErrNoTable
}

// TablesPrefixedBy returns the list of tables prefixed by this pattern.
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

// WithColumn returns the list of tables using this column.
func (d *Database) TablesWithColumn(column string) []DataTable {
	return d.fd[column]
}

// SetViewsPath overloads the default views file path.
// This file stocks all user views.
// If the database has been built, reloads views and indexes.
func (d *Database) SetViewsFile(p string) error {
	d.viewFile = p

	if d.ready {
		// Views already load as data set, so we need to reload it.
		if err := d.loadViewsAndIndexes(); err != nil {
			d.ready = false
			return err
		}
	}

	return nil
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

// loadFile
func (d *Database) loadFile(path string) ([]byte, error) {
	// Gets path of reports reference.
	p, err := filepath.Abs(filepath.Join(d.dir, path))
	if err != nil {
		return []byte{}, err
	}
	// Gets reference in yaml format.
	ymlFile, err := ioutil.ReadFile(p)
	if err != nil {
		return []byte{}, err
	}
	return ymlFile, nil
}

// loadReports loads all report table and returns it as Database or error.
func (d *Database) loadReports() error {
	// Gets the content of the Yaml configuration file.
	ymlFile, err := d.loadFile(fmt.Sprintf(reportsPath, d.Version))
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
	// Gets the content of the Yaml configuration file.
	ymlFile, err := d.loadFile(d.viewFile)
	if err != nil {
		return err
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

// loadViewsAndIndexes loads all views and builds indexes.
func (d *Database) loadViewsAndIndexes() error {
	if err := d.loadViews(); err != nil {
		return ErrLoadViews
	}
	if err := d.buildColumnsIndex(); err != nil {
		return ErrLoadColumns
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
	cnames := stmt.Columns()
	cols := stmt.SourceQuery().Columns()
	csize := len(cols)
	if size := len(cnames); size > 0 && size != csize {
		return nil, ErrMismatchColumns
	}
	data.Cols = make([]Column, csize)
	for i := 0; i < csize; i++ {
		col, err := t.newColumn(cols[i], cnames[i])
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
	view.Cols = make([]Column, csize)
	copy(view.Cols, data.Cols)

	// Finally adds the table source.
	view.View = data

	return view, nil
}

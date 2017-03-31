package awqlparse

import "strconv"

// String outputs a create view statement.
func (s CreateViewStatement) String() (q string) {
	if s.SourceName() == "" {
		return
	}
	q = "CREATE "
	if s.ReplaceMode() {
		q += "OR REPLACE "
	}
	q += "VIEW " + s.SourceName()

	// Concatenates field names.
	cols := s.Columns()
	if size := len(cols); size > 0 {
		q += " ("
		for i, c := range cols {
			if i > 0 {
				q += ", "
			}
			q += c.Name()
		}
		q += ")"
	}

	// Adds the data source.
	v := s.View.String()
	if v == "" {
		return ""
	}
	q += " AS " + v

	return
}

// String outputs a describe statement.
func (s DescribeStatement) String() (q string) {
	if s.SourceName() == "" {
		return
	}
	q = "DESC "
	if s.FullMode() {
		q += "FULL "
	}
	q += s.SourceName()

	cols := s.Columns()
	if len(cols) == 1 {
		q += " " + cols[0].Name()
	}

	return
}

// String outputs a select statement.
func (s SelectStatement) String() (q string) {
	if len(s.Columns()) == 0 || s.SourceName() == "" {
		return
	}
	q = "SELECT "

	// Adds columns.
	for i, c := range s.Columns() {
		if i > 0 {
			q += ", "
		}
		// Distinct value.
		var s string
		if c.Distinct() {
			s = "DISTINCT "
		}
		s += c.Name()
		// Method name.
		if method, ok := c.UseFunction(); ok {
			s = method + "(" + s + ")"
		}
		// Alias.
		if c.Alias() != "" {
			s += " AS " + c.Alias()
		}
		q += s
	}

	// Adds data source name.
	q += " FROM " + s.SourceName()
	q += s.whereString()
	q += s.duringString()

	// Adds group by clause.
	g := s.GroupList()
	if gs := len(g); gs > 0 {
		q += " GROUP BY "
		for i := 0; i < gs; i++ {
			if i > 0 {
				q += ", "
			}
			q += strconv.Itoa(g[i].Position())
		}
	}

	// Adds sort orders.
	o := s.OrderList()
	if os := len(o); os > 0 {
		q += " ORDER BY "
		for i := 0; i < os; i++ {
			if i > 0 {
				q += ", "
			}
			q += strconv.Itoa(o[i].Position())
			if o[i].SortDescending() {
				q += " DESC"
			}
		}
	}

	// Adds limit clause.
	if rc, ok := s.PageSize(); ok {
		q += " LIMIT "
		if si := s.StartIndex(); si > 0 {
			q += strconv.Itoa(si) + ", "
		}
		q += strconv.Itoa(rc)
	}

	return
}

// LegacyString outputs a select statement as expected by Google Adwords.
// Indeed, aggregate functions, ORDER BY, GROUP BY and LIMIT are not supported for reports.
func (s SelectStatement) LegacyString() (q string) {
	if len(s.Columns()) == 0 || s.SourceName() == "" {
		return
	}
	q = "SELECT "

	// Concatenates selected fields.
	for i, c := range s.Columns() {
		if i > 0 {
			q += ", "
		}
		q += c.Name()
	}

	// Adds data source name.
	q += " FROM " + s.SourceName()
	q += s.whereString()
	q += s.duringString()

	return
}

// duringString outputs a where clause.
func (s SelectStatement) whereString() (q string) {
	if len(s.ConditionList()) > 0 {
		q += " WHERE "
		for i, c := range s.ConditionList() {
			if i > 0 {
				q += " AND "
			}
			q += c.Name() + " " + c.Operator()
			val, lit := c.Value()
			if len(val) > 1 {
				q += " ["
				for y, v := range val {
					if y > 0 {
						q += " ,"
					}
					if lit {
						q += " " + v
					} else {
						q += " " + strconv.Quote(v)
					}
				}
				q += " ]"
			} else if lit {
				q += " " + val[0]
			} else {
				q += " " + strconv.Quote(val[0])
			}
		}
	}

	return
}

// duringString outputs a during clause.
func (s SelectStatement) duringString() (q string) {
	d := s.DuringList()
	if ds := len(d); ds > 0 {
		q += " DURING "
		if ds == 2 {
			q += d[0] + "," + d[1]
		} else {
			// Literal range date
			q += d[0]
		}
	}

	return
}

// String outputs a show statement.
func (s ShowStatement) String() (q string) {
	q = "SHOW "
	if s.FullMode() {
		q += "FULL "
	}
	q += "TABLES"

	if p, used := s.LikePattern(); used {
		var str string
		switch {
		case p.Equal != "":
			str = p.Equal
		case p.Contains != "":
			str = "%" + p.Contains + "%"
		case p.Prefix != "":
			str = p.Prefix + "%"
		case p.Suffix != "":
			str = "%" + p.Suffix
		}
		q += " LIKE " + strconv.Quote(str)
	}

	if str, used := s.WithFieldName(); used {
		q += " WITH " + strconv.Quote(str)
	}

	return
}

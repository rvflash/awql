# Awql Database

[![GoDoc](https://godoc.org/github.com/rvflash/awql-db?status.svg)](https://godoc.org/github.com/rvflash/awql-db)
[![Build Status](https://img.shields.io/travis/rvflash/awql-db.svg)](https://travis-ci.org/rvflash/awql-db)
[![Code Coverage](https://img.shields.io/codecov/c/github/rvflash/awql-db.svg)](http://codecov.io/github/rvflash/awql-db?branch=master)
[![Go Report Card](https://goreportcard.com/badge/github.com/rvflash/awql-db)](https://goreportcard.com/report/github.com/rvflash/awql-db)


All information about Adwords reports represented as tables or user views.


## Data Source Name

The optional parts are marked by squared brackets:

```
APIVersion[:NoAutoLoad][|SrcDirectory][|ViewFilePath]
```

The first part with `APIVersion` can contains an option to disable auto-loading.

#### `APIVersion`

```
Type:           string
Valid Values:   <version>
Default:        v201708
```
Version of the Adwords API to use.

#### `NoAutoLoad`

```
Type:           bool
Valid Values:   true, false
Default:        false
```
If true, the database is not loaded at the opening.

#### `SrcDirectory`

Path to the folder that stores the database configuration files. 

#### `ViewFilePath`

Enables to overload the path to the views configuration file.


## Example
 
```go
import db "github.com/rvflash/awql-db"

awql, _ := db.Open("v201708")
for _, table := range awql.TablesPrefixedBy("VIDEO") {
    fmt.Println(table.SourceName())
}
// Output: VIDEO_PERFORMANCE_REPORT
```
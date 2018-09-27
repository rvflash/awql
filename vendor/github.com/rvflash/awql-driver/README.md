# Awql Database Driver

[![GoDoc](https://godoc.org/github.com/rvflash/awql-driver?status.svg)](https://godoc.org/github.com/rvflash/awql-driver)
[![Build Status](https://img.shields.io/travis/rvflash/awql-driver.svg)](https://travis-ci.org/rvflash/awql-driver)
[![Code Coverage](https://img.shields.io/codecov/c/github/rvflash/awql-driver.svg)](http://codecov.io/github/rvflash/awql-driver?branch=master)
[![Go Report Card](https://goreportcard.com/badge/github.com/rvflash/awql-driver)](https://goreportcard.com/report/github.com/rvflash/awql-driver)


AWQL driver for Go's sql package.


## Installation

Simple install the package to your $GOPATH with the go tool:

```bash
~ $ go get -u github.com/rvflash/awql-driver
```

## Usage

AWQL Driver is an implementation of Go's `database/sql/driver` interface.
You only need to import the driver and can use the full database/sql API then.

Use `awql` as `driverName` and a valid [DSN](#data-source-name) as `dataSourceName`:

```go
import "database/sql"
import _ "github.com/rvflash/awql-driver"

db, err := sql.Open("awql", "AdwordsID:APIVersion|DeveloperToken|AccessToken")
```

## Data Source Name

The Data Source Name has two common formats, the optional parts are marked by squared brackets:

#### `Minimal`
```
AdwordsID|DeveloperToken[|AccessToken]
```
#### `OAuth credentials`
```
AdwordsID|DeveloperToken[|ClientID|ClientSecret|RefreshToken]
```

The first part with `AdwordsID` can contains Adwords API options. A DSN in its fullest form:
```
AdwordsID[:APIVersion:SupportsZeroImpressions:SkipColumnHeader:UseRawEnumValues]|DeveloperToken[|AccessToken][|ClientID|ClientSecret|RefreshToken]
```

Alternatively, [NewDSN](https://godoc.org/github.com/rvflash/awql-driver#Dsn) can be used to create a DSN string by filling a struct.


#### `AdwordsID`

The client customer ID is the account number of the AdWords client account you want to manage via the API, usually in the form 123-456-7890.

#### `APIVersion`

```
Type:           string
Valid Values:   <version>
Default:        v201809
```
Version of the Adwords API to use.

#### `SupportsZeroImpressions`

```
Type:           bool
Valid Values:   true, false
Default:        false
```
If true, report output will include rows where all specified metric fields are zero, provided the requested fields and predicates support zero impressions.
If false, report output will not include such rows. 
Thus, even if this header is false and the Impressions of a row is zero, the row is still returned in case any of the specified metric fields have non-zero values. 

#### `SkipColumnHeader`

```
Type:           bool
Valid Values:   true, false
Default:        false
```
If true, report output will not include a header row containing field names.
If false or not specified, report output will include the field names.

#### `UseRawEnumValues`

```
Type:           bool
Valid Values:   true, false
Default:        false
```
Set to true if you want the returned format to be the actual enum value, for example, "IMAGE_AD" instead of "Image ad".
Set to false or omit this header if you want the returned format to be the display value.

#### `DeveloperToken`

The developer token identifies your app to the AdWords API.
Only approved tokens can connect to the API for production AdWords accounts; pending tokens can connect only to test accounts.

#### `AccessToken`

Use to grant connection to Google API

#### `ClientID`

Client identifier, used to connect to Adwords with OAuth2.

#### `ClientSecret`

Client secret, used to connect to Adwords with OAuth2.

#### `RefreshToken`

Because OAuth2 access expires after a limited time, an OAuth2 refresh token is used to automatically renew OAuth2 access.


## Examples

### Simple Awql query
 
```go
// Ignores errors for the demo.
query := "SELECT ExternalCustomerId, AccountDescriptiveName FROM ACCOUNT_PERFORMANCE_REPORT"
db, _ := sql.Open("awql", "123-456-7890|dEve1op3er7okeN|ya29.Acc3ss-7ok3n")
stmt, _ := db.Query(query)
for stmt.Next() {
    var id int
    var name string
    stmt.Scan(&id, &name)
    fmt.Printf("%v: %v\n", id, name)
    // Output: 1234567890: Rv
}
```
 
### Awql query row with arguments

```go
// Ignores errors for the demo.
var name string
query := "SELECT CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT Where CampaignId = ?"
row := db.QueryRow(query, 123456789)
row.Scan(&name)
fmt.Printf("%v\n", name)
// Output: Campaign #19
```

### Advanced sample

```go
// Instantiates a data source name.
dsn := awql.NewDsn("123-456-7890")
dsn.DeveloperToken = "dEve1op3er7okeN"
dsn.ClientID = "1234567890-Aw91.apps.googleusercontent.com"
dsn.ClientSecret = "C13nt5e0r3t"
dsn.RefreshToken = "1/n-R3fr35h70k3n"

// Ignores errors for the demo.
query := "SELECT ConversionTypeName, AllConversions, ConversionValue FROM CRITERIA_PERFORMANCE_REPORT DURING LAST_7_DAYS"
db, _ := sql.Open("awql", dsn.String())
stmt, _ := db.Query(query)
cols, _ := stmt.Columns()
fmt.Printf("%q\n", cols)
// Output: ["Conversion name" "All conv." "Total conv. value"]

// Copy references into the slice
size := len(cols)
vals := make([]string, size)
ints := make([]interface{}, size)
for i := range ints {
    ints[i] = &vals[i]
}
for stmt.Next() {
    stmt.Scan(ints...)
    fmt.Printf("%q\n", vals)
}
// Output:
// ["Transactions (Phone)" "6.0" "362.33"]
// ["Transactions (Web)" "1.0" "89.3"]
```

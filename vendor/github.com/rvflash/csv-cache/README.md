# CSV Cache

[![GoDoc](https://godoc.org/github.com/rvflash/csv-cache?status.svg)](https://godoc.org/github.com/rvflash/csv-cache)
[![Build Status](https://img.shields.io/travis/rvflash/csv-cache.svg)](https://travis-ci.org/rvflash/csv-cache)
[![Code Coverage](https://img.shields.io/codecov/c/github/rvflash/csv-cache.svg)](http://codecov.io/github/rvflash/csv-cache?branch=master)
[![Go Report Card](https://goreportcard.com/badge/github.com/rvflash/csv-cache)](https://goreportcard.com/report/github.com/rvflash/csv-cache)


Cache data in CSV files in Golang.


## Installation

Simple install the package to your $GOPATH with the go tool:

```bash
$ go get -u github.com/rvflash/csv-cache
```

## Usage

This small library allows you to manage CSV data with a time to live, based on the last modified time.

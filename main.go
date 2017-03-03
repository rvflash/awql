package main

import (
	"fmt"
	"log"
	"os"

	"github.com/rvflash/awql/conf"
	"github.com/rvflash/awql/ui"
)

// main launches the AWQL Command-Line Tool.
//
// Usage of awql:
// 	-A	Disables automatic rehashing
// 	-B	Enables printing of results using comma as the column separator
// 	-D string
// 		Google OAuth developer token
// 	-T string
// 		Google OAuth access token
// 	-V string
// 		Google Adwords API version (default "v201702")
// 	-c	Enables data caching
// 	-e string
// 		Execute AWQL statement, disables interactive use
// 	-i string
// 		Google Adwords account ID
// 	-v	Enables verbose mode
// 	-z	Enables fetching of reports with the support of zero impressions
//
func main() {
	conf := conf.New()
	if err := conf.Init(); err != nil {
		exit(err)
	}
	// Launch the environment.
	var src ui.Scanner
	if conf.IsInteractive() {
		src = ui.NewTerminal(conf)
	} else {
		src = ui.NewCommandLine(conf)
	}
	if err := src.Scan(); err != nil {
		exit(err)
	}
}

// exit causes the current program to exit with the appropriate status code.
func exit(err error) {
	if err == nil {
		// See you soon.
		os.Exit(0)
	}
	// An error occurred, exits with the appropriate behavior.
	switch err.(type) {
	case *conf.FlagError:
		fmt.Println(err)
		conf.Usage()
		os.Exit(1)
	default:
		log.Fatal(err)
	}
}

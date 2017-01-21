package config

import (
	"flag"
	"fmt"
	"regexp"

	"github.com/rvflash/awql-driver"
)

const (
	UsageAccountId      = "Google Adwords account ID"
	UsageAccessToken    = "Google OAuth access token"
	UsageDeveloperToken = "Google OAuth developer token"
	UsageApiVersion     = "Google Adwords API version"
	UsageQuery          = "Execute AWQL statement"
)

// CmdError represents an error for the command-line tool.
type FlagError struct {
	s string
}

// NewCmdError returns an error of the parse error.
func NewFlagError(text string) error {
	return &FlagError{s: text}
}

// Error returns the message of the parse error.
func (e *FlagError) Error() string {
	return fmt.Sprintf("FlagError.INVALID (%v)", e.s)
}

// Flag represents all options passed by the program.
type Flag struct {
	AccountId,
	AccessToken,
	ApiVersion,
	DeveloperToken,
	Query *string
	Batch,
	ZeroImpressions,
	NoRehash,
	Verbose,
	Caching *bool
}

// Check checks all required inputs.
func (o *Flag) Check() error {
	// Expected account identifier like 123-456-7890
	if ok, _ := regexp.MatchString("^[0-9]{3}-[0-9]{3}-[0-9]{4}$", *o.AccountId); !ok {
		return NewFlagError(UsageAccountId)
	}
	// Adwords API version support.
	// @todo Improves it with a slice of versions from awql_db package.
	if *o.ApiVersion != awql.ApiVersion {
		return NewFlagError(UsageApiVersion)
	}
	// Authenticate credentials.
	if *o.AccessToken != "" && *o.DeveloperToken == "" {
		return NewFlagError(UsageDeveloperToken)
	}
	if *o.AccessToken == "" && *o.DeveloperToken != "" {
		return NewFlagError(UsageAccessToken)
	}
	return nil
}

// Parse parses the command-line flags from os.Args[1:]
// It returns an instance of Flag.
func Parse() *Flag {
	opts := &Flag{}
	// Google Adwords account ID.
	opts.AccountId = flag.String("i", "", UsageAccountId)
	// Google OAuth access token.
	opts.AccessToken = flag.String("T", "", UsageAccessToken)
	// Google OAuth developer token.
	opts.DeveloperToken = flag.String("D", "", UsageDeveloperToken)
	// Google Adwords API version.
	opts.ApiVersion = flag.String("V", awql.ApiVersion, UsageApiVersion)
	// Awql query (non interactive use).
	opts.Query = flag.String("e", "", UsageQuery+", disables interactive use")
	// Disables automatic rehashing.
	opts.NoRehash = flag.Bool("A", false, "Disables automatic rehashing")
	// Enables batch mode.
	opts.Batch = flag.Bool("B", false, "Enables printing of results using comma as the column separator")
	// Supports zero impressions
	opts.ZeroImpressions = flag.Bool("z", false, "Enables fetching of reports with the support of zero impressions")
	// Verbose mode.
	opts.Verbose = flag.Bool("v", false, "Enables verbose mode")
	// Data caching.
	opts.Caching = flag.Bool("c", false, "Enables data caching")
	// Parses the command-line flags.
	flag.Parse()

	return opts
}

// Usage prints a usage message documenting all defined command-line flags.
func Usage() {
	flag.Usage()
}

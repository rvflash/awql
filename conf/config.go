package conf

import (
	"os"
	"os/user"
	"path/filepath"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
	"github.com/rvflash/awql/driver"
)

type Options interface {
	AccountID() string
	APIVersion() string
	ExecuteStmt() string
	IsInteractive() bool
	SupportsZeroImpressions() bool
	UseBatchMode() bool
	UseVerboseMode() bool
	WithAutoRehash() bool
	WithCache() bool
}

type Settings interface {
	Options
	Dsn() string
	CacheDir() string
	DatabaseDir() string
	HistoryFile() string
	Init() error
}

// Context represents the program properties.
type Context struct {
	homeDir string
	tk      *Credentials
	opts    *Flag
}

// NewCredentials returns an instance of Credentials.
func New() *Context {
	return &Context{opts: Parse()}
}

// AccountID returns the Account ID.
func (c *Context) AccountID() string {
	return *c.opts.AccountID
}

// AccountID returns the API version.
func (c *Context) APIVersion() string {
	return *c.opts.APIVersion
}

// CacheDir returns the path to store cache files.
func (c *Context) CacheDir() string {
	if c.homeDir == "" {
		return ""
	}
	return filepath.Join(c.homeDir, "cache")
}

// DatabaseFile returns the path to the database.
func (c *Context) DatabaseDir() string {
	dir, err := filepath.Abs("vendor/github.com/rvflash/awql-db/src")
	if err != nil {
		return ""
	}
	return dir
}

// Dsn outputs the data source name.
func (c *Context) Dsn() string {
	// Data source name used to connect to Adwords.
	dsn := awql.NewDsn(c.AccountID())
	dsn.APIVersion = c.APIVersion()
	dsn.SupportsZeroImpressions = c.SupportsZeroImpressions()
	dsn.SkipColumnHeader = true

	// Credentials.
	dsn.AccessToken = c.tk.AccessToken
	dsn.ClientID = c.tk.ClientID
	dsn.ClientSecret = c.tk.ClientSecret
	dsn.DeveloperToken = c.tk.DeveloperToken
	dsn.RefreshToken = c.tk.RefreshToken

	return driver.NewDsn(
		c.DatabaseDir(), dsn.String(), c.CacheDir(), c.WithCache(),
	).String()
}

// ExecuteStmt returns the statement to execute.
func (c *Context) ExecuteStmt() string {
	return *c.opts.Query
}

// HistoryFilePath returns the path to the history file.
func (c *Context) HistoryFile() string {
	if c.homeDir == "" {
		return ""
	}
	return filepath.Join(c.homeDir, "history")
}

// Set retrieves and saves the default authenticate information.
func (c *Context) Init() error {
	// Checks for required flags.
	if err := c.opts.Check(); err != nil {
		return err
	}
	// Checks if it's a supported Adwords API versions.
	// Opens a connection to Awql DB without load anything.
	if _, err := db.Open(c.APIVersion() + ":true|" + c.DatabaseDir()); err != nil {
		return err
	}
	// Create the tool home directory.
	if err := c.mkDirHome(); err != nil {
		return err
	}
	// Checks credential to authenticate to Adwords.
	switch {
	case *c.opts.AccessToken != "":
		// Use temporary credential.
		c.tk = NewTmpCredentials(*c.opts.AccessToken, *c.opts.DeveloperToken)
	case !c.useDefaultAuth():
		// Aks authenticate credentials to user.
		c.tk = AskCredentials()
		if err := c.tk.Save(c.filePath()); err != nil {
			return err
		}
	default:
		// Get authenticate credentials from configuration file.
		c.tk = NewCredentials()
		if err := c.tk.Get(c.filePath()); err != nil {
			return err
		}
	}
	return nil
}

// IsInteractive returns true if query as passed as flag.
func (c *Context) IsInteractive() bool {
	return *c.opts.Query == ""
}

// SupportsZeroImpressions returns true if the support of zero impressions is enable.
func (c *Context) SupportsZeroImpressions() bool {
	return *c.opts.ZeroImpressions
}

// UseBatchMode returns true if raw mode is required.
// It will print results using colon as the column separator, with each row on a new line.
func (c *Context) UseBatchMode() bool {
	return *c.opts.Batch
}

// UseVerboseMode returns true if more output about what the program does is required.
func (c *Context) UseVerboseMode() bool {
	return *c.opts.Verbose
}

// WithAutoRehash returns true if automatic rehashing is enable.
func (c *Context) WithAutoRehash() bool {
	return !*c.opts.NoRehash
}

// WithCache returns true if the cache is enable.
func (c *Context) WithCache() bool {
	return *c.opts.Caching
}

// filePath returns the path to the config file.
func (c *Context) filePath() string {
	if c.homeDir == "" {
		return ""
	}
	return filepath.Join(c.homeDir, "config")
}

// mkDirHome creates if not already exists the home directory.
func (c *Context) mkDirHome() error {
	if c.homeDir != "" {
		// Directory already made.
		return nil
	}
	// Gets user properties.
	usr, err := user.Current()
	if err != nil {
		return err
	}
	// If not exists, create the user home directory of Awql tool: .awql
	c.homeDir = filepath.Join(usr.HomeDir, ".awql")
	if _, err := os.Stat(c.homeDir); os.IsNotExist(err) {
		if err := os.Mkdir(c.homeDir, os.ModePerm); err != nil {
			return err
		}
	}
	// Tries to create the cache directory: .awql/cache
	if err := os.Mkdir(c.CacheDir(), os.ModePerm); !os.IsExist(err) {
		return err
	}
	return nil
}

// Valid returns true if the config file exists.
func (c *Context) useDefaultAuth() bool {
	if c.homeDir == "" {
		return false
	}
	// Checks if config file exists.
	_, err := os.Stat(c.filePath())

	return err == nil
}

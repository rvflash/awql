package csvcache

import (
	"encoding/csv"
	"errors"
	"hash/fnv"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// File extension.
const csvExt = ".csv"

// Error messages.
var (
	ErrNotStored  = errors.New("item not stored")
	ErrCacheMiss  = errors.New("cache miss")
	ErrInvalidKey = errors.New("invalid key")
)

// Item is an item to be got or stored in the cache directory.
type Item struct {
	Key   string
	Value [][]string
}

// key returns the key string as expected by this cache: an uint64 hash as string.
func (d *Item) name() string {
	if _, err := strconv.ParseUint(d.Key, 10, 64); err == nil {
		return d.Key
	}
	h := fnv.New64()
	if _, err := h.Write([]byte(d.Key)); err != nil {
		return ""
	}
	return strconv.FormatUint(h.Sum64(), 10)
}

// Cache is a wrapper around os.File providing simple file caching.
type Cache struct {
	dir    string
	maxAge time.Duration
}

// New returns an instance of Cache.
func New(dir string, expire time.Duration) *Cache {
	return &Cache{dir: strings.TrimSpace(dir), maxAge: expire}
}

// Add writes the given item, if no value already exists for its key.
// ErrNotStored is returned if that condition is not met.
func (c *Cache) Add(d *Item) error {
	path, err := c.filePath(d)
	if err != nil {
		return ErrNotStored
	}
	if _, err = os.Stat(path); err == nil {
		return ErrNotStored
	}
	return c.write(d)
}

// Delete deletes the item with the provided key.
// ErrCacheMiss is returned if the item didn't already exist in the cache.
func (c *Cache) Delete(key string) error {
	return c.remove(&Item{Key: key})
}

// DeleteAll deletes all items in the cache.
func (c *Cache) DeleteAll() error {
	for _, d := range c.listAll() {
		if err := c.remove(d); err != nil {
			return err
		}
	}
	return nil
}

// FlushAll flushes all expired items in the cache.
func (c *Cache) FlushAll() error {
	for _, d := range c.listAll() {
		if !c.isExpired(d) {
			continue
		}
		if err := c.remove(d); err != nil {
			return err
		}
	}
	return nil
}

// Get gets the item for the given key.
// ErrCacheMiss is returned for a cache miss.
func (c *Cache) Get(key string) ([][]string, error) {
	d := &Item{Key: key}
	path, err := c.filePath(d)
	if err != nil {
		return nil, ErrCacheMiss
	}

	// Checks the modification time of the file.
	if c.isExpired(d) {
		return nil, ErrCacheMiss
	}

	// Tries to open it.
	f, err := os.Open(path)
	if err != nil {
		return nil, ErrCacheMiss
	}
	defer f.Close()

	// Retrieves each lines of CSV file.
	r := csv.NewReader(f)
	data, err := r.ReadAll()
	if err != nil {
		return nil, ErrCacheMiss
	}
	return data, nil
}

// Replace writes the given item, but only if the server has already its key.
// ErrNotStored is returned if that condition is not met.
func (c *Cache) Replace(d *Item) error {
	path, err := c.filePath(d)
	if err != nil {
		return ErrNotStored
	}
	if _, err = os.Stat(path); os.IsNotExist(err) {
		return ErrNotStored
	}
	return c.write(d)
}

// Set writes the given item, unconditionally.
// ErrNotStored is returned if we can not create a file into this directory.
func (c *Cache) Set(d *Item) error {
	return c.write(d)
}

// filePath returns the absolute path for this file name or an error.
func (c *Cache) filePath(d *Item) (string, error) {
	if d.name() == "" || c.dir == "" {
		return "", ErrInvalidKey
	}
	return filepath.Abs(filepath.Join(c.dir, d.name()+csvExt))
}

// isExpired is a predicate which determines if the file should be updated.
func (c *Cache) isExpired(d *Item) bool {
	path, err := c.filePath(d)
	if err != nil {
		return true
	}
	fi, err := os.Stat(path)
	if err != nil {
		return true
	}
	return time.Now().After(fi.ModTime().Add(c.maxAge))
}

// listAll returns the list of available item keys.
func (c *Cache) listAll() (items []*Item) {
	files, err := ioutil.ReadDir(c.dir)
	if err != nil {
		return
	}
	for _, f := range files {
		if f.IsDir() || !strings.HasSuffix(f.Name(), csvExt) {
			continue
		}
		items = append(items, &Item{Key: strings.TrimSuffix(f.Name(), csvExt)})
	}
	return
}

// remove deletes the item or returns an error.
func (c *Cache) remove(d *Item) error {
	path, err := c.filePath(d)
	if err != nil {
		return ErrCacheMiss
	}
	if _, err = os.Stat(path); os.IsNotExist(err) {
		return ErrCacheMiss
	}
	return os.Remove(path)
}

// write saves the value in a file named using the key.
func (c *Cache) write(d *Item) error {
	path, err := c.filePath(d)
	if err != nil {
		return ErrNotStored
	}

	// Tries to open it.
	f, err := os.Create(path)
	if err != nil {
		return ErrNotStored
	}
	defer f.Close()

	// Saves all lines into the given file.
	w := csv.NewWriter(f)
	if err := w.WriteAll(d.Value); err != nil {
		return ErrNotStored
	}
	if err := w.Error(); err != nil {
		return ErrNotStored
	}
	return nil
}

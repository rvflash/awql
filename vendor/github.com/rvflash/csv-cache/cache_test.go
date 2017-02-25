package csvcache_test

import (
	"io/ioutil"
	"os"
	"reflect"
	"testing"
	"time"

	"github.com/rvflash/csv-cache"
)

func TestCache_Workflow(t *testing.T) {
	// Creates a temporary working directory.
	dir, err := ioutil.TempDir("", "csvfile")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	// Defines the working directory of the cache.
	c := csvcache.New(dir, 10*time.Second)
	// Tries to get an unknown key.
	_, err = c.Get("rv")
	if !reflect.DeepEqual(err, csvcache.ErrCacheMiss) {
		t.Error("expected non-existent key to be cache missed")
	}
	// Sets the first key/value.
	if err := c.Set(&csvcache.Item{Key: "rv"}); err != nil {
		t.Error("expected successful setting of first key")
	}
	// Gets the first key.
	data, err := c.Get("rv")
	if err != nil {
		t.Error("expected successful getting of first key")
	}
	if data != nil {
		t.Error("expected no data")
	}
	// Tries to add an existing key.
	if err := c.Add(&csvcache.Item{Key: "rv"}); !reflect.DeepEqual(err, csvcache.ErrNotStored) {
		t.Error("expected existent key not to be overwrited with add method")
	}
	// Tries to replace an unknown key.
	if err := c.Replace(&csvcache.Item{Key: "12345"}); !reflect.DeepEqual(err, csvcache.ErrNotStored) {
		t.Error("expected error not stored if we try to replace value with an unknown key")
	}
	// Replaces the value for this key.
	if err := c.Replace(&csvcache.Item{Key: "rv"}); err != nil {
		t.Errorf("expected no error when we try to replace an existent key, received: %v\n", err)
	}
	// Deletes an unknown key.
	if err := c.Delete("12345"); !reflect.DeepEqual(err, csvcache.ErrCacheMiss) {
		t.Errorf("expected cache miss error when we try to delete an unknown key, received: %v\n", err)
	}
	// Deletes an existing key.
	if err := c.Delete("rv"); err != nil {
		t.Errorf("expected no error when we try to delete an existent key, received: %v\n", err)
	}
	// Gets the same key.
	if _, err := c.Get("rv"); !reflect.DeepEqual(err, csvcache.ErrCacheMiss) {
		t.Error("expected cache miss error on deleted item")
	}
	// Now, tries again to add it..
	if err := c.Add(&csvcache.Item{Key: "rv"}); err != nil {
		t.Errorf("expected no error when we try to add an non-existent key, received: %v\n", err)
	}
}

func TestCache_Multi(t *testing.T) {
	// Creates a temporary working directory.
	dir, err := ioutil.TempDir("", "csvfile")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	// Defines the working directory of the cache with low time duration.
	c := csvcache.New(dir, 1*time.Second)
	// Create files with various time duration.
	if err := c.Set(&csvcache.Item{Key: "0"}); err != nil {
		t.Fatal("can not to add data in cache")
	}
	if err := c.Set(&csvcache.Item{Key: "1"}); err != nil {
		t.Fatal("can not to add data in cache")
	}
	// Have a break
	time.Sleep(1 * time.Second)
	// Add an other key
	if err := c.Set(&csvcache.Item{Key: "2"}); err != nil {
		t.Fatal("can not to add data in cache")
	}
	// Deletes all data with TTL exceeded.
	if err := c.FlushAll(); err != nil {
		t.Errorf("expected no error to flush all deprecated data, received: %v\n", err)
	}
	if files, _ := ioutil.ReadDir(dir); len(files) != 1 {
		t.Errorf("expected only 1 file after flushing, received: %d", len(files))
	}
	if err := c.Set(&csvcache.Item{Key: "2"}); err != nil {
		t.Fatal("can not to add data in cache")
	}
	// Deletes all data.
	if err := c.DeleteAll(); err != nil {
		t.Errorf("expected no error to delete all data in cache, received: %v\n", err)
	}
	if files, _ := ioutil.ReadDir(dir); len(files) > 0 {
		t.Errorf("expected 0 file after deleting all entries, received: %d", len(files))
	}
}

func TestCache_NonExistentDir(t *testing.T) {
	c := csvcache.New("/test/csv-cache", 10*time.Second)
	// Tries to set the first key/value.
	if err := c.Set(&csvcache.Item{Key: "rv"}); !reflect.DeepEqual(err, csvcache.ErrNotStored) {
		t.Error("expected error with non-existent cache directory")
	}
}

func TestCache_NoDir(t *testing.T) {
	c := csvcache.New("", 10*time.Second)
	// Tries to set the first key/value.
	if err := c.Set(&csvcache.Item{Key: "rv"}); !reflect.DeepEqual(err, csvcache.ErrNotStored) {
		t.Error("expected error with non-specified cache directory")
	}
}

func TestCache_Expire(t *testing.T) {
	// Creates a temporary working directory.
	dir, err := ioutil.TempDir("", "csvfile")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)

	// Defines the working directory of the cache with low time duration.
	c := csvcache.New(dir, 1*time.Second)
	// Tries to set the first key/value.
	if err := c.Set(&csvcache.Item{Key: "rv"}); err != nil {
		t.Error("expected successful setting of first key")
	}
	// Gets the same key.
	if _, err := c.Get("rv"); err != nil {
		t.Error("expected successful getting of first key")
	}
	// Have a break
	time.Sleep(1 * time.Second)
	// Tries to get it again after that the time to live exceeded.
	if _, err := c.Get("rv"); !reflect.DeepEqual(err, csvcache.ErrCacheMiss) {
		t.Error("expected cache miss error after cache duration exceeded")
	}
}

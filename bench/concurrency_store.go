// Goroutines over SQLite: N units, each M keyed lookups in a table of K
// rows -- the store partner of bench/concurrency.pl's store_green, which
// runs the same probes as green threads over cocolog's --embed store.
//
//   concurrency_store PATH N K M
//
// Builds the table and its PRIMARY KEY in one transaction, then starts N
// goroutines, each with a connection of its own and a prepared select, and
// prints answer(done) and the sum the probes made. Every unit probes the
// same key sequence, so the total is N times one unit's.
//
// The driver is the C library through cgo, not database/sql: Go has no
// SQLite driver without a module, and this box has libsqlite3.

package main

/*
#cgo LDFLAGS: -lsqlite3
#include <sqlite3.h>
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"os"
	"strconv"
	"sync"
	"unsafe"
)

func atoi(s string) int {
	n, err := strconv.Atoi(s)
	if err != nil {
		panic(err)
	}
	return n
}

func openDB(path string) *C.sqlite3 {
	c := C.CString(path)
	defer C.free(unsafe.Pointer(c))
	var db *C.sqlite3
	if C.sqlite3_open(c, &db) != C.SQLITE_OK {
		panic("sqlite3_open failed")
	}
	return db
}

func execSQL(db *C.sqlite3, sql string) {
	c := C.CString(sql)
	defer C.free(unsafe.Pointer(c))
	var msg *C.char
	if C.sqlite3_exec(db, c, nil, nil, &msg) != C.SQLITE_OK {
		panic(C.GoString(msg))
	}
}

func prepare(db *C.sqlite3, sql string) *C.sqlite3_stmt {
	c := C.CString(sql)
	defer C.free(unsafe.Pointer(c))
	var st *C.sqlite3_stmt
	if C.sqlite3_prepare_v2(db, c, -1, &st, nil) != C.SQLITE_OK {
		panic("sqlite3_prepare failed")
	}
	return st
}

// one unit: M probes on a connection of its own, the key sequence the
// Prolog side's, answered as the sum of the values found. THE PROBES RUN
// INSIDE ONE TRANSACTION, as a green unit's do: the store's connection has
// a session per thread and a transaction open across the unit's reads, so
// the SQLite partner opens one too (autocommit would make each SELECT a
// transaction of its own, a different thing measured).
func probe(path string, k, m int) int64 {
	db := openDB(path)
	defer C.sqlite3_close(db)
	execSQL(db, "begin")
	st := prepare(db, "select v from f where k=?")
	defer C.sqlite3_finalize(st)
	var sum int64
	for i := m; i > 0; i-- {
		key := int64((i*37)%k) + 1
		C.sqlite3_reset(st)
		C.sqlite3_bind_int64(st, 1, C.sqlite3_int64(key))
		if C.sqlite3_step(st) == C.SQLITE_ROW {
			sum += int64(C.sqlite3_column_int64(st, 0))
		}
	}
	execSQL(db, "commit")
	return sum
}

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintln(os.Stderr, "usage: concurrency_store build PATH K | store PATH N K M")
		os.Exit(2)
	}
	mode := os.Args[1]
	switch mode {
	case "build": // seed K rows, outside the timed region
		path := os.Args[2]
		k := atoi(os.Args[3])
		db := openDB(path)
		execSQL(db, "create table if not exists f (k integer primary key, v integer)")
		execSQL(db, "begin")
		st := prepare(db, "insert or replace into f values (?,?)")
		for i := k; i > 0; i-- {
			C.sqlite3_reset(st)
			C.sqlite3_bind_int64(st, 1, C.sqlite3_int64(i))
			C.sqlite3_bind_int64(st, 2, C.sqlite3_int64((i*7)%1000))
			C.sqlite3_step(st)
		}
		C.sqlite3_finalize(st)
		execSQL(db, "commit")
		C.sqlite3_close(db)
		fmt.Println("answer(done)")
		return
	case "store": // the timed probes
	default:
		fmt.Fprintln(os.Stderr, "usage: concurrency_store build PATH K | store PATH N K M")
		os.Exit(2)
	}
	path := os.Args[2]
	n := atoi(os.Args[3])
	k := atoi(os.Args[4])
	m := atoi(os.Args[5])

	var wg sync.WaitGroup
	var mu sync.Mutex
	var total int64
	for u := 0; u < n; u++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			s := probe(path, k, m)
			mu.Lock()
			total += s
			mu.Unlock()
		}()
	}
	wg.Wait()
	fmt.Printf("answer(done)\ntotal(%d)\n", total)
}

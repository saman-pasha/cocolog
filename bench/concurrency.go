// The goroutine lanes of bench/concurrency.sh: N goroutines on the same
// spin(M) work, and the light lanes -- N goroutines that do nothing, and N
// that yield (runtime.Gosched) K times. Go's runtime schedules goroutines
// itself (M:N over the OS threads), so unlike the cocolog green lane these
// may use the cores. The work is summed and printed in the work lane so the
// compiler cannot prove the loop away.
//
//	go run bench/concurrency.go work 8 1000000
//	go run bench/concurrency.go light 10000
//	go run bench/concurrency.go lightyield 10000 100
package main

import (
	"fmt"
	"os"
	"runtime"
	"strconv"
	"sync"
	"sync/atomic"
)

func spin(n int64) int64 {
	var x int64
	for n > 0 {
		x += n
		n--
	}
	return x
}

func main() {
	mode := os.Args[1]
	n, _ := strconv.Atoi(os.Args[2])
	switch mode {
	case "work":
		m, _ := strconv.Atoi(os.Args[3])
		work(n, m)
	case "light":
		light(n, 0)
	case "lightyield":
		k, _ := strconv.Atoi(os.Args[3])
		light(n, k)
	default:
		os.Exit(2)
	}
}

func work(n, m int) {
	var wg sync.WaitGroup
	var total int64
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			atomic.AddInt64(&total, spin(int64(m)))
		}()
	}
	wg.Wait()
	fmt.Println("answer(done)")
	fmt.Printf("work(%d)\n", total)
}

func light(n, yields int) {
	var wg sync.WaitGroup
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := 0; j < yields; j++ {
				runtime.Gosched()
			}
		}()
	}
	wg.Wait()
	fmt.Println("answer(done)")
}

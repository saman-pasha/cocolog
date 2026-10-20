// The Rust lanes: OS threads on the same spin/1 work as the other lanes,
// and the same light lanes -- N threads that do nothing, and N that yield
// K times -- answer-gated like every lane.
//
//   concurrency_rust work N M        N threads, each spin(M); prints
//                                    answer(done) and work(total)
//   concurrency_rust light N         N threads, each true, joined
//   concurrency_rust lightyield N K  N threads, each yielding K times
//
// std::thread makes one OS thread per task, so this is the library(thread)
// lane's model, not green's or Go's: the work lane can use N cores, and the
// light lanes pay a thread's creation. std::thread::yield_now() is the
// cooperative yield, yield/0's and runtime.Gosched()'s.

use std::env;
use std::process;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::Arc;
use std::thread;

fn spin(mut n: i64) -> i64 {
    let mut x: i64 = 0;
    while n > 0 {
        x = x.wrapping_add(n);
        n -= 1;
    }
    x
}

fn usage() -> ! {
    eprintln!("usage: concurrency_rust work N M | light N | lightyield N K");
    process::exit(2);
}

fn main() {
    let a: Vec<String> = env::args().collect();
    if a.len() < 3 {
        usage();
    }
    let mode = a[1].as_str();
    let n: usize = match a[2].parse() {
        Ok(v) => v,
        Err(_) => usage(),
    };
    match mode {
        "work" => {
            let m: i64 = match a.get(3).and_then(|s| s.parse().ok()) {
                Some(v) => v,
                None => usage(),
            };
            let total = Arc::new(AtomicI64::new(0));
            let mut hs = Vec::with_capacity(n);
            for _ in 0..n {
                let t = Arc::clone(&total);
                hs.push(thread::spawn(move || {
                    t.fetch_add(spin(m), Ordering::Relaxed);
                }));
            }
            for h in hs {
                h.join().unwrap();
            }
            println!("answer(done)");
            println!("work({})", total.load(Ordering::Relaxed));
        }
        "light" => {
            let mut hs = Vec::with_capacity(n);
            for _ in 0..n {
                hs.push(thread::spawn(|| {}));
            }
            for h in hs {
                h.join().unwrap();
            }
            println!("answer(done)");
        }
        "lightyield" => {
            let k: usize = match a.get(3).and_then(|s| s.parse().ok()) {
                Some(v) => v,
                None => usage(),
            };
            let mut hs = Vec::with_capacity(n);
            for _ in 0..n {
                hs.push(thread::spawn(move || {
                    for _ in 0..k {
                        thread::yield_now();
                    }
                }));
            }
            for h in hs {
                h.join().unwrap();
            }
            println!("answer(done)");
        }
        _ => usage(),
    }
}

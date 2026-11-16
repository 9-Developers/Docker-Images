unsafe extern "C" {
    fn answer() -> i32;
}

fn main() {
    assert_eq!(unsafe { answer() }, 42);
    let handle = std::thread::spawn(|| String::from("cross compilation works"));
    println!("{}", handle.join().unwrap());
}

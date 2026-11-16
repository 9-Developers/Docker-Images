fn main() {
    cc::Build::new().file("answer.c").compile("answer");
    println!("cargo:rerun-if-changed=answer.c");
}

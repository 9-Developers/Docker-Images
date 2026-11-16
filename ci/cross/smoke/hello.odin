package main

import "core:fmt"

main :: proc() {
    values := make([]int, 3)
    defer delete(values)
    values[0] = 42
    assert(values[0] == 42)
    ratio := f64(values[0]) / 8.0
    assert(ratio == 5.25)
    fmt.println("cross compilation works", values[0], ratio)
}

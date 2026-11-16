package main

/*
#include <stdlib.h>
static int answer(void) { return 42; }
*/
import "C"

import "fmt"

func main() {
	p := C.malloc(16)
	if p == nil || C.answer() != 42 {
		panic("cgo failed")
	}
	C.free(p)
	fmt.Println("cgo smoke ok")
}

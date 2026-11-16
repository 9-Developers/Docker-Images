package main

import "fmt"

func main() {
	done := make(chan int)
	go func() { done <- 42 }()
	if <-done != 42 {
		panic("goroutine failed")
	}
	fmt.Println("go smoke ok")
}

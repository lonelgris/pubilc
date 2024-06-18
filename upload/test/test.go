package main

import (
	"flag"
	"fmt"
	"strings"
)

var str = flag.String("str", "", "str")

func main() {

	flag.Parse()

	if strings.Contains(*str, "\\n") {
		fmt.Println("str contains newline")

		*str = strings.ReplaceAll(*str, "\\n", "\n")
	}

	fmt.Print(*str)
}

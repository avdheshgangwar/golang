package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"unicode/utf8"
)

func main() {

	//printfAndPrintln()
	//swapValues()
	//ifElseIf()
	//shadowingGotcha()
	//stringLen()
	//banger()
	//rawStringLiteralPath()
	//replaceName()
	//compareArray()
	//twoDimenArray()
	//reverseString()
	//createSlice()
	//CreateMapWithOutMake()
	//CreateMapWithMake()
	// var p int = 10
	// var q int = 20
	// fmt.Printf("p = %d and q = %d", p, q)
	// //callByVlaues(p, q)
	// //callByReference(&p, &q)
	// fmt.Printf("\np = %d and q = %d", p, q)
	//variadicFunction("red", "blue", "green", "yellow")
	// defer secondDefer()
	// firstDefer()
	// defer thirdDefer()
	// defer fourthDefer()
	// fifthDefer()
	// panicAndRecover(5)
	// panicAndRecover(2)
	// panicAndRecover(0)
	// panicAndRecover(8)

}

func printfAndPrintln() {
	var (
		planet   = "venus"
		distance = 261
		orbital  = 224.701
		hasLife  = false
	)

	//swiss army knife %v verb
	fmt.Printf("Planet: %v\n", planet)
	fmt.Printf("Distance: %v millions kms\n", distance)
	fmt.Printf("Orbital Period: %v days\n", orbital)
	fmt.Printf("Does %v have life? %v\n", planet, hasLife)

	// argument indexing - indexes start from 1
	fmt.Printf(
		"%v is %v away. Think! %[2]v kms! %[1]v OMG.\n",
		planet, distance,
	)

	// why use other verbs than? because: type-safety
	// Incorrect verbs:

	// fmt.Printf("Planet: %d\n", planet)
	// fmt.Printf("Distance: %s millions kms\n", distance)
	// fmt.Printf("Orbital Period: %t days\n", orbital)
	// fmt.Printf("Does %v has life? %f\n", planet, hasLife)

	//correct verbs:
	fmt.Printf("Planet: %s\n", planet)
	fmt.Printf("Distance: %d millions kms\n", distance)
	fmt.Printf("Orbital Period: %f days\n", orbital)
	fmt.Printf("Does %s has life? %t\n", planet, hasLife)

	//precision
	fmt.Printf("Orbital Period: %f days\n", orbital)
	fmt.Printf("Orbital Period: %.0f days\n", orbital)
	fmt.Printf("Orbital Period: %.1f days\n", orbital)
	fmt.Printf("Orbital Period: %.2f days\n", orbital)
	fmt.Printf("Type of %.2f is %[1]T\n", 3.14)
	//Println:
	fmt.Println("Planet:", planet)
	fmt.Println("Distance:", distance)
	fmt.Println("Orbital Period:", orbital)
	fmt.Println("Does Planet has life?", hasLife)

}
func ifElseIf() {

	args := os.Args
	l := len(args) - 1
	n, err := strconv.Atoi(os.Args[1])

	fmt.Printf("There is olen(args)ne: %q\n", l)
	if l == 0 {
		fmt.Println("Give me args")
	} else if l == 1 {
		fmt.Printf("There is one: %q\n", args[1])
	} else if l == 2 {
		fmt.Printf(
			`There are two: "%s %s"`+"\n",
			args[1], args[2],
		)
	} else {
		fmt.Printf("There are %d arguments\n", l)
	}

	fmt.Println("Converted number    :", n)
	fmt.Println("Returned error value:", err)
}

//shadowing varibale
func shadowingGotcha() {
	var (
		n   int
		err error
	)
	a := os.Args
	fmt.Println("Number", len(a))

	if len(a) != 2 {

		fmt.Println("Give me a number")
	} else if n, err = strconv.Atoi(a[1]); err != nil {
		fmt.Printf("Cannot convert %q.\n", a[1])
	} else {
		n *= 2
		fmt.Printf("%s * 2 is %d\n", a[1], n)
	}
	fmt.Printf(" %dYou have been shadowing\n", n)
}

//Swap elements using multivalues assignments
func swapValues() {
	i := []int{100, 200, 300, 400}
	fmt.Println(i)

	i[0], i[1], i[2], i[3] = i[3], i[2], i[1], i[0]
	fmt.Println(i)

	a, b := 1, 2
	fmt.Println(a, b)

	a, b = b, a // note the lack of ':' since no new variables are being created
	fmt.Println(a, b)
	//Case2
	j := []int{1, 2, 3, 4}
	fmt.Println(j)

	j[0], j[3] = j[3], j[0]
	fmt.Println(j)

}

//Calcualate lenght of string
func stringLen() {
	//Non english(non unicode) letters take more than 1 bytes it means len func calcuate the bytes of string not lenghth of string
	name := "avdheshC+>CYRILLICЙ"
	fmt.Println(len(name))
	//output=20
	//We use utf8 packages for count of the length of string
	lenstring := utf8.RuneCountInString(name)
	fmt.Println(lenstring)
	//output=19

}

//add ! on the bases of input lenght
func banger() {
	msg := os.Args[1]
	l := len(msg)
	s := msg + strings.Repeat("!", l)
	fmt.Println(s)
	//input is hi then output is hi!!
	//input is hey then output is hey!!!
	s = strings.ToUpper(s)
	fmt.Println(s)
	//input is hi then output is HI!!
	//input is hey then output is HEY!!!
}
func rawStringLiteralPath() {
	// this one uses a raw string literal
	path := `c:\\program files\\duper super\\fun.txt\n +
		c:\\program files\\really\\funny.png`
	fmt.Println(path)
}

//add dynamically  some words in the string
func replaceName() {
	// replace and concatenate the `name` variable
	// after `hi ` below
	//msg := `hi CONCATENATE-NAME-VARIABLE-HERE!how are you?`
	name := os.Args[1]

	msg := `hi ` + name + `!
how are you?`

	fmt.Println(msg)
}
func compareArray() {

	// Arrays
	a1 := [3]int{4, 5, 6}
	a2 := [...]int{4, 5, 6}
	a3 := [3]int{9, 5, 3}

	// Comparing arrays using == operator
	fmt.Println(a1 == a2)
	fmt.Println(a2 == a3)
	fmt.Println(a1 == a3)

	// Output
	// true
	// false
	// false
}

func twoDimenArray() {

	// Creating and initializing
	// 2-dimensional array
	// Using shorthand declaration
	// Here the (,) Comma is necessary
	arr := [3][2]string{{"C #", "C"}, {"Java", "Scala"},
		{"C++", "Go"}}

	// Accessing the values of the
	// array Using for loop
	fmt.Println("Elements of Array 1")
	for x := 0; x < 3; x++ {
		for y := 0; y < 2; y++ {

			fmt.Println(arr[x][y])
		}
	}

	// Creating a 2-dimensional
	// array using var keyword
	// and initializing a multi
	// -dimensional array using index
	var arr1 [2][2]int
	arr1[0][0] = 100
	arr1[0][1] = 200
	arr1[1][0] = 300
	arr1[1][1] = 400

	// Accessing the values of the array
	fmt.Println("Elements of array 2")
	for p := 0; p < 2; p++ {
		for q := 0; q < 2; q++ {
			fmt.Println(arr1[p][q])
		}
	}

}
func reverseString() {
	input := "121387729"
	// Get Unicode code points.
	n := 0
	rune := make([]rune, len(input))
	for _, r := range input {
		rune[n] = r
		n++
	}
	rune = rune[0:n]
	// Reverse
	for i := 0; i < n/2; i++ {
		rune[i], rune[n-1-i] = rune[n-1-i], rune[i]
	}
	// Convert back to UTF-8.
	output := string(rune)
	fmt.Println(output)
}
func createSlice() {

	// Creating a slice
	myslice := []string{"This", "is", "the", "tutorial",
		"of", "Go", "language"}

	// Iterate using for loop
	for e := 0; e < len(myslice); e++ {
		fmt.Println(myslice[e])
	}
}

//Create map with make function
func CreateMapWithOutMake() {
	var map1 map[string]string
	if map1 == nil {

		fmt.Println("True")
	} else {

		fmt.Println("False")
	}
	// Creating and initializing a map
	// Using shorthand declaration and
	// using map literals
	map_2 := map[int]string{
		91: "Go",
		92: "Java",
		93: ".net",
		94: "php",
	}
	map_2[95] = "node"

	fmt.Println(map_2)
}

// Creating a map Using make() function
func CreateMapWithMake() {
	var map1 = make(map[string]string)
	fmt.Println(map1)

	if map1 == nil {

		fmt.Println("True")
	} else {

		fmt.Println("False")
	}
	map1["name"] = "Avdhesh"
	map1["mobile"] = "7839293847"
	map1["address"] = "Gurugram"
	map1["education"] = "B.tech"
	fmt.Println(map1)
	//iterate map using for loop

	for k, v := range map1 {
		fmt.Println(k, v)
	}

	//add key value pair in the map
	map1["nickname"] = "Bablu"
	map1["Hobbies"] = "Dancing"
	//update key value pair in the map
	map1["address"] = "BLR"
	fmt.Println(map1)
	// Retrieving values with the help of keys

	fmt.Println("Address: ", map1["address"])
	// Checking the key is available or not in the map1 map
	address, ok := map1["address"]
	fmt.Println("\nKey present or not:", ok)
	fmt.Println("Value:", address)
	// Without value using the blank identifier It will only give check result
	_, ok1 := map1["Hobbies"]
	fmt.Println("Value:", ok1)
	//Delete key from map1
	delete(map1, "address")
	fmt.Println(map1)

}
func callByVlaues(a, b int) int {
	var o int
	o = a
	a = b
	b = o

	return o
}
func callByReference(a, b *int) int {
	var o int
	o = *a
	*a = *b
	*b = o

	return o
}
func variadicFunction(s ...string) {
	fmt.Println(s)
}
func firstDefer() {
	fmt.Println("First")
}
func secondDefer() {
	fmt.Println("Second")
}
func thirdDefer() {
	fmt.Println("Third")
}
func fourthDefer() {
	fmt.Println("Fourth")
}
func fifthDefer() {
	fmt.Println("Fifth")
}

var result = 1

func panicAndRecover(n int) {

	defer func() {
		if r := recover(); r != nil {
			fmt.Println(r)
		}
	}()

	if n == 0 {
		panic(errors.New("Cannot multiply a number by zero"))
	} else {
		result *= n
		fmt.Println("Output: ", result)
	}
}

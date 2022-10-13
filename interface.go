package main

import (
	"fmt"
	"math"
)

//create interface
type geometry interface {
	area() float64
	perim() float64
}

//implement this interface on rect and circle types.
type reactangle struct {
	height, width float64
}
type circle struct {
	radius float64
}

//implement geometry on rectangle.
func (r reactangle) area() float64 {
	return r.height * r.width
}
func (r reactangle) perim() float64 {
	return 2*r.width + 2*r.height
}

//implement geometry on circle
func (c circle) area() float64 {
	return math.Pi * c.radius * c.radius
}

func (c circle) perim() float64 {
	return 2 * math.Pi * c.radius
}

//we can call methods that are in the named interface.
func measure(g geometry) {
	fmt.Println(g)
	fmt.Println(g.area())
	fmt.Println(g.perim())

}

//instances of these structs as arguments to measure.
func main() {
	r := reactangle{height: 10, width: 20}
	c := circle{radius: 5}
	measure(r)
	measure(c)
}

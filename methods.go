package methods

import "fmt"

type reactangle struct {
	height, width int
}

//write pointer type method to calculate are
func (r *reactangle) area() int {
	return r.height * r.width

}

//write value type method to calculate perimeter
func (r reactangle) perim() int {
	return 2 * r.height * 2 * r.width

}
func main1() {
	r := reactangle{width: 10, height: 20}

	fmt.Println("area", r.area())
	fmt.Println("perim", r.perim())

	rp := &r
	fmt.Println("pointerarea", rp.area())
	fmt.Println("pointerperim", rp.perim())

}

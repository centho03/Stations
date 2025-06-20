package types

import "fmt"

type Station struct {
	Name string
	X, Y int
}

type Network struct {
	Stations    map[string]*Station
	Connections map[string][]string
}

// NewNetwork creates a new, empty network
func NewNetwork() *Network {
	return &Network{
		Stations:    make(map[string]*Station),
		Connections: make(map[string][]string),
	}
}

type Train struct {
	ID       int
	Name     string
	Position string
	Path     []string
	PathPos  int
}

func NewTrain(id int, start string) *Train {
	return &Train{
		ID:       id,
		Name:     fmt.Sprintf("T%d", id),
		Position: start,
		Path:     []string{},
		PathPos:  0,
	}
}

type Move struct {
	Turn   int
	Trains []TrainMove
}

type TrainMove struct {
	TrainName string
	To        string
}

func (tm TrainMove) String() string {
	return fmt.Sprintf("%s-%s", tm.TrainName, tm.To)
}
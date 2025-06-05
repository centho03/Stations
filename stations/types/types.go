package types

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

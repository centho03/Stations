package graph

// Node represents a train station in the network
type Node struct {
	Name      string
	Neighbors []string
}

// Graph represents the entire network of stations.
type Graph struct {
	Nodes map[string]*Node // Key: station name, Value: pointer to Node
}

// NewGraph initializes an empty Graph.
func NewGraph() *Graph {
	return &Graph{
		Nodes: make(map[string]*Node),
	}
}

// AddNode adds a station to the graph if it doesn't already exist.
func (g *Graph) AddNode(name string) {
	if _, exists := g.Nodes[name]; !exists {
		g.Nodes[name] = &Node{
			Name:      name,
			Neighbors: []string{},
		}
	}
}

// AddEdge adds a two-way (undirected) connection between 2 stations.
func (g *Graph) AddEdge(from, to string) {
	g.AddNode(from)
	g.AddNode(to)

	// Add 'to' as a neighbor of 'from', if not already present.
	if !contains(g.Nodes[from].Neighbors, to) {
		g.Nodes[from].Neighbors = append(g.Nodes[from].Neighbors, to)
	}
	// Add 'from' as a neighbor of 'to', if not already present.
	if !contains(g.Nodes[to].Neighbors, from) {
		g.Nodes[to].Neighbors = append(g.Nodes[to].Neighbors, from)
	}
}

// contains checks if a slice contains a string.
func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}

func (g *Graph) Copy() *Graph {
    newGraph := NewGraph()
    for name, node := range g.Nodes {
        newGraph.AddNode(name)
        for _, neighbor := range node.Neighbors {
            newGraph.AddEdge(name, neighbor)
        }
    }
    return newGraph
}

func (g *Graph) RemoveEdge(from, to string) {
	// Remove 'to' from 'from's neighbor list
	newNeighbors := []string{}
	for _, neighbor := range g.Nodes[from].Neighbors {
		if neighbor != to {
			newNeighbors = append(newNeighbors, neighbor)
		}
	}
	g.Nodes[from].Neighbors = newNeighbors

	// Remove 'from' from 'to's neighbor list (since undirected)
	newNeighbors = []string{}
	for _, neighbor := range g.Nodes[to].Neighbors {
		if neighbor != from {
			newNeighbors = append(newNeighbors, neighbor)
		}
	}
	g.Nodes[to].Neighbors = newNeighbors
}

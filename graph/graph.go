package graph

import (
	"gitea.kood.tech/innocentkwizera1/stations/types"
)

type Node struct {
	Name      string
	Neighbors []*Node
	Visited   bool
	Distance  int
	Parent    *Node
}

type Graph struct {
	Nodes map[string]*Node
}

func NewGraph() *Graph {
	return &Graph{
		Nodes: make(map[string]*Node),
	}
}

func (g *Graph) AddNode(name string) {
	if _, exists := g.Nodes[name]; !exists {
		g.Nodes[name] = &Node{Name: name, Neighbors: []*Node{}}
	}
}

func (g *Graph) AddEdge(from, to string) {
	fromNode := g.Nodes[from]
	toNode := g.Nodes[to]
	
	if fromNode != nil && toNode != nil {
		fromNode.Neighbors = append(fromNode.Neighbors, toNode)
	}
}

func (g *Graph) PathExists(start, end string) bool {
	if start == end {
		return true
	}
	
	visited := make(map[string]bool)
	return g.dfs(start, end, visited)
}

func (g *Graph) dfs(current, target string, visited map[string]bool) bool {
	if current == target {
		return true
	}
	
	visited[current] = true
	
	if node, exists := g.Nodes[current]; exists {
		for _, neighbor := range node.Neighbors {
			if !visited[neighbor.Name] {
				if g.dfs(neighbor.Name, target, visited) {
					return true
				}
			}
		}
	}
	
	return false
}

func (g *Graph) FindShortestPath(start, end string) []string {
	if start == end {
		return []string{start}
	}
	
	// Reset all nodes
	for _, node := range g.Nodes {
		node.Visited = false
		node.Distance = -1
		node.Parent = nil
	}
	
	queue := []*Node{}
	startNode := g.Nodes[start]
	startNode.Distance = 0
	startNode.Visited = true
	queue = append(queue, startNode)
	
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		
		if current.Name == end {
			// Reconstruct path
			path := []string{}
			for current != nil {
				path = append([]string{current.Name}, path...)
				current = current.Parent
			}
			return path
		}
		
		for _, neighbor := range current.Neighbors {
			if !neighbor.Visited {
				neighbor.Visited = true
				neighbor.Distance = current.Distance + 1
				neighbor.Parent = current
				queue = append(queue, neighbor)
			}
		}
	}
	
	return nil
}

func (g *Graph) FindMultiplePaths(start, end string, maxPaths int) [][]string {
	paths := [][]string{}
	
	// Find first shortest path
	firstPath := g.FindShortestPath(start, end)
	if firstPath == nil {
		return paths
	}
	
	paths = append(paths, firstPath)
	
	if maxPaths == 1 {
		return paths
	}
	
	// Try to find alternative paths by temporarily removing edges
	for i := 1; i < len(firstPath)-1 && len(paths) < maxPaths; i++ {
		// Create a copy of the graph without the edge
		tempGraph := g.copyWithoutEdge(firstPath[i-1], firstPath[i])
		altPath := tempGraph.FindShortestPath(start, end)
		if altPath != nil && !pathExists(paths, altPath) {
			paths = append(paths, altPath)
		}
	}
	
	return paths
}

func (g *Graph) copyWithoutEdge(from, to string) *Graph {
	newGraph := NewGraph()
	
	// Copy all nodes
	for name := range g.Nodes {
		newGraph.AddNode(name)
	}
	
	// Copy all edges except the specified one
	for _, node := range g.Nodes {
		for _, neighbor := range node.Neighbors {
			if !(node.Name == from && neighbor.Name == to) {
				newGraph.AddEdge(node.Name, neighbor.Name)
			}
		}
	}
	
	return newGraph
}

func pathExists(paths [][]string, newPath []string) bool {
	for _, path := range paths {
		if len(path) == len(newPath) {
			same := true
			for i := range path {
				if path[i] != newPath[i] {
					same = false
					break
				}
			}
			if same {
				return true
			}
		}
	}
	return false
}

func BuildGraph(network *types.Network) *Graph {
	g := NewGraph()
	
	// Add all nodes
	for name := range network.Stations {
		g.AddNode(name)
	}
	
	// Add all edges
	for from, neighbors := range network.Connections {
		for _, to := range neighbors {
			g.AddEdge(from, to)
		}
	}
	
	return g
}
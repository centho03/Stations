package graph

import "sort"

// ShortestPath finds the shortest path between two stations using BFS.
// Results are deterministic by processing neighbors in alphabetical order.
func (g *Graph) ShortestPath(from, to string) []string {
	if from == to {
		return []string{from}
	}
	if _, ok := g.Nodes[from]; !ok {
		return nil
	}
	if _, ok := g.Nodes[to]; !ok {
		return nil
	}

	// BFS structures
	queue := []string{from}
	visited := map[string]bool{from: true}
	prev := map[string]string{}

	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		
		// Get neighbors and sort them for deterministic results
		neighbors := make([]string, len(g.Nodes[current].Neighbors))
		copy(neighbors, g.Nodes[current].Neighbors)
		sort.Strings(neighbors) // ← KEY IMPROVEMENT: Deterministic order
		
		for _, neighbor := range neighbors {
			if !visited[neighbor] {
				visited[neighbor] = true
				prev[neighbor] = current
				if neighbor == to {
					// Build path:
					path := []string{to}
					for node := to; node != from; node = prev[node] {
						path = append([]string{prev[node]}, path...)
					}
					return path
				}
				queue = append(queue, neighbor)
			}
		}
	}
	return nil // No path found
}

// PathExists checks if a path exists between two stations
func (g *Graph) PathExists(from, to string) bool {
	return g.ShortestPath(from, to) != nil
}

// FindAllShortestPaths finds all shortest paths of the same length
func (g *Graph) FindAllShortestPaths(from, to string) [][]string {
	if from == to {
		return [][]string{{from}}
	}
	if _, ok := g.Nodes[from]; !ok {
		return nil
	}
	if _, ok := g.Nodes[to]; !ok {
		return nil
	}

	// Modified BFS to find all shortest paths
	queue := [][]string{{from}}
	visited := map[string]int{from: 0}
	allPaths := [][]string{}
	targetDistance := -1

	for len(queue) > 0 {
		currentPath := queue[0]
		queue = queue[1:]
		current := currentPath[len(currentPath)-1]
		currentDistance := len(currentPath) - 1

		// If we've found paths to target and current path is longer, stop
		if targetDistance != -1 && currentDistance > targetDistance {
			break
		}

		if current == to {
			if targetDistance == -1 {
				targetDistance = currentDistance
			}
			if currentDistance == targetDistance {
				allPaths = append(allPaths, currentPath)
			}
			continue
		}

		// Get neighbors and sort for deterministic results
		neighbors := make([]string, len(g.Nodes[current].Neighbors))
		copy(neighbors, g.Nodes[current].Neighbors)
		sort.Strings(neighbors)

		for _, neighbor := range neighbors {
			newDistance := currentDistance + 1
			
			// Only proceed if we haven't visited this node at a shorter distance
			if prevDistance, exists := visited[neighbor]; !exists || newDistance <= prevDistance {
				if !exists || newDistance < prevDistance {
					visited[neighbor] = newDistance
				}
				
				newPath := make([]string, len(currentPath)+1)
				copy(newPath, currentPath)
				newPath[len(newPath)-1] = neighbor
				queue = append(queue, newPath)
			}
		}
	}

	return allPaths
}

// Distance returns the shortest distance between two stations
func (g *Graph) Distance(from, to string) int {
	path := g.ShortestPath(from, to)
	if path == nil {
		return -1 // No path exists
	}
	return len(path) - 1 // Number of edges
}
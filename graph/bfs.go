package graph

import "sort"

// ShortestPath finds the shortest path using BFS with deterministic ordering
func (g *Graph) ShortestPath(from, to string) []string {
	if from == to {
		return []string{from}
	}
	
	// Check nodes exist
	if _, ok := g.Nodes[from]; !ok {
		return nil
	}
	if _, ok := g.Nodes[to]; !ok {
		return nil
	}

	// BFS
	type queueItem struct {
		node string
		path []string
	}
	
	queue := []queueItem{{from, []string{from}}}
	visited := map[string]bool{from: true}
	
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		
		// Get neighbors and sort them for deterministic behavior
		neighbors := make([]string, len(g.Nodes[current.node].Neighbors))
		copy(neighbors, g.Nodes[current.node].Neighbors)
		sort.Strings(neighbors)
		
		for _, neighbor := range neighbors {
			if !visited[neighbor] {
				visited[neighbor] = true
				newPath := make([]string, len(current.path)+1)
				copy(newPath, current.path)
				newPath[len(newPath)-1] = neighbor
				
				if neighbor == to {
					return newPath
				}
				
				queue = append(queue, queueItem{neighbor, newPath})
			}
		}
	}
	
	return nil
}

// PathExists checks if a path exists
func (g *Graph) PathExists(from, to string) bool {
	return g.ShortestPath(from, to) != nil
}

// Distance returns the shortest distance
func (g *Graph) Distance(from, to string) int {
	path := g.ShortestPath(from, to)
	if path == nil {
		return -1
	}
	return len(path) - 1
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
	
	type queueItem struct {
		node string
		path []string
	}
	
	queue := []queueItem{{from, []string{from}}}
	visited := map[string]int{from: 0} // node -> shortest distance
	allPaths := [][]string{}
	shortestDist := -1
	
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		currentDist := len(current.path) - 1
		
		// If we found the shortest distance and this path is longer, skip
		if shortestDist != -1 && currentDist > shortestDist {
			continue
		}
		
		if current.node == to {
			if shortestDist == -1 {
				shortestDist = currentDist
			}
			if currentDist == shortestDist {
				allPaths = append(allPaths, current.path)
			}
			continue
		}
		
		// Get sorted neighbors
		neighbors := make([]string, len(g.Nodes[current.node].Neighbors))
		copy(neighbors, g.Nodes[current.node].Neighbors)
		sort.Strings(neighbors)
		
		for _, neighbor := range neighbors {
			newDist := currentDist + 1
			
			// Only proceed if we haven't visited or found a path of same length
			if prevDist, exists := visited[neighbor]; !exists || newDist <= prevDist {
				if !exists || newDist < prevDist {
					visited[neighbor] = newDist
				}
				
				newPath := make([]string, len(current.path)+1)
				copy(newPath, current.path)
				newPath[len(newPath)-1] = neighbor
				
				queue = append(queue, queueItem{neighbor, newPath})
			}
		}
	}
	
	return allPaths
}
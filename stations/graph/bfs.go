package graph

// ShortestPath finds the shortest path between two stations using BFS.
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
		for _, neighbor := range g.Nodes[current].Neighbors {
			if !visited[neighbor] {
				visited[neighbor] = true
				prev[neighbor] = current
				if neighbor == to {
					// build path:
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






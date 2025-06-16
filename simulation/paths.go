package simulation

import (
	"gitea.kood.tech/innocentkwizera1/stations/graph"
)

// FindDisjointPaths finds edge-disjoint paths between start and end
func FindDisjointPaths(g *graph.Graph, start, end string, maxPaths int) [][]string {
	paths := [][]string{}
	
	// First, try the standard approach
	gCopy := g.Copy()
	
	for len(paths) < maxPaths {
		path := gCopy.ShortestPath(start, end)
		if path == nil {
			break
		}
		
		paths = append(paths, path)
		
		// Remove edges
		for i := 0; i < len(path)-1; i++ {
			gCopy.RemoveEdge(path[i], path[i+1])
		}
	}
	
	// If we found fewer than 3 paths, try a different approach
	// Find paths that start with different first edges from the start node
	if len(paths) < 3 && maxPaths >= 3 {
		// Get all neighbors of start
		startNode, exists := g.Nodes[start]
		if exists && len(startNode.Neighbors) > len(paths) {
			// Track which first neighbors we've used
			usedFirstNeighbors := make(map[string]bool)
			for _, path := range paths {
				if len(path) > 1 {
					usedFirstNeighbors[path[1]] = true
				}
			}
			
			// Try to find paths through unused neighbors
			for _, neighbor := range startNode.Neighbors {
				if !usedFirstNeighbors[neighbor] && len(paths) < maxPaths {
					// Force a path through this neighbor
					forcedPath := findPathThroughNode(g, start, neighbor, end)
					if forcedPath != nil {
						// Check if unique
						unique := true
						for _, existing := range paths {
							if pathsEqual(forcedPath, existing) {
								unique = false
								break
							}
						}
						if unique {
							paths = append(paths, forcedPath)
						}
					}
				}
			}
		}
	}
	
	// Fallback: ensure at least one path
	if len(paths) == 0 {
		path := g.ShortestPath(start, end)
		if path != nil {
			paths = append(paths, path)
		}
	}
	
	return paths
}

// findPathThroughNode finds a path that goes through a specific first node
func findPathThroughNode(g *graph.Graph, start, through, end string) []string {
	// First check if 'through' is a neighbor of start
	startNode, exists := g.Nodes[start]
	if !exists {
		return nil
	}
	
	isNeighbor := false
	for _, n := range startNode.Neighbors {
		if n == through {
			isNeighbor = true
			break
		}
	}
	
	if !isNeighbor {
		return nil
	}
	
	// Find path from 'through' to 'end'
	pathFromThrough := g.ShortestPath(through, end)
	if pathFromThrough == nil {
		return nil
	}
	
	// Combine: start -> through -> ... -> end
	fullPath := make([]string, len(pathFromThrough)+1)
	fullPath[0] = start
	copy(fullPath[1:], pathFromThrough)
	
	return fullPath
}

func pathsEqual(p1, p2 []string) bool {
	if len(p1) != len(p2) {
		return false
	}
	for i := range p1 {
		if p1[i] != p2[i] {
			return false
		}
	}
	return true
}
package simulation

import (
	"gitea.kood.tech/innocentkwizera1/stations/graph"
)

// FindDisjointPaths finds edge-disjoint paths
func FindDisjointPaths(g *graph.Graph, start, end string, needed int) [][]string {
	paths := [][]string{}
	
	// Make a working copy
	gCopy := g.Copy()
	
	// Keep finding shortest paths and removing their edges
	for len(paths) < needed {
		path := gCopy.ShortestPath(start, end)
		if path == nil {
			break
		}
		
		paths = append(paths, path)
		
		// Remove all edges in this path
		for i := 0; i < len(path)-1; i++ {
			gCopy.RemoveEdge(path[i], path[i+1])
		}
		
		// Stop if we have enough paths
		if len(paths) >= needed {
			break
		}
	}
	
	// If no paths found, try to get at least one from original graph
	if len(paths) == 0 {
		path := g.ShortestPath(start, end)
		if path != nil {
			paths = append(paths, path)
		}
	}
	
	return paths
}
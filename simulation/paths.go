package simulation

import (
	"sort"

	"gitea.kood.tech/innocentkwizera1/stations/graph"
)

// Enhanced path finding with quality scoring and sorting
func FindDisjointPaths(g *graph.Graph, start, end string, maxPaths int) [][]string {
	paths := [][]string{}
	gCopy := g.Copy()

	for i := 0; i < maxPaths; i++ {
		path := gCopy.ShortestPath(start, end)
		if path == nil {
			break
		}

		paths = append(paths, path)
		// Remove all edges in this path for next search
		for j := 0; j < len(path)-1; j++ {
			gCopy.RemoveEdge(path[j], path[j+1])
		}
	}

	// Sort paths by length (shortest first) for optimal assignment
	sort.Slice(paths, func(i, j int) bool {
		lengthI := len(paths[i]) - 1 // number of moves
		lengthJ := len(paths[j]) - 1
		if lengthI != lengthJ {
			return lengthI < lengthJ // shorter paths first
		}
		// If same length, sort by first station name for consistency
		return paths[i][0] < paths[j][0]
	})

	return paths
}

// Additional utility function for path quality assessment
func assessPathQuality(path []string, g *graph.Graph) int {
	if len(path) < 2 {
		return 0
	}

	quality := 100 // base quality

	// Shorter paths are better
	quality -= (len(path) - 2) * 10

	// Paths through high-degree nodes might have more conflicts
	for i := 1; i < len(path)-1; i++ { // skip start and end
		if node, exists := g.Nodes[path[i]]; exists {
			if len(node.Neighbors) > 3 { // high-degree node
				quality -= 5
			}
		}
	}

	return quality
}

// Find all possible paths (not just edge-disjoint) for complex scenarios
func FindAllPaths(g *graph.Graph, start, end string, maxPaths int) [][]string {
	allPaths := [][]string{}

	// Use iterative approach to find multiple paths
	visited := make(map[string]bool)
	var dfs func(current string, path []string, target string)

	dfs = func(current string, path []string, target string) {
		if len(allPaths) >= maxPaths {
			return
		}

		if current == target {
			// Found a path
			pathCopy := make([]string, len(path))
			copy(pathCopy, path)
			allPaths = append(allPaths, pathCopy)
			return
		}

		if len(path) > 10 { // Prevent infinite loops
			return
		}

		if node, exists := g.Nodes[current]; exists {
			for _, neighbor := range node.Neighbors {
				if !visited[neighbor] {
					visited[neighbor] = true
					newPath := append(path, neighbor)
					dfs(neighbor, newPath, target)
					visited[neighbor] = false
				}
			}
		}
	}

	visited[start] = true
	dfs(start, []string{start}, end)

	// Sort by length and quality
	sort.Slice(allPaths, func(i, j int) bool {
		lengthI := len(allPaths[i]) - 1
		lengthJ := len(allPaths[j]) - 1

		if lengthI != lengthJ {
			return lengthI < lengthJ
		}

		qualityI := assessPathQuality(allPaths[i], g)
		qualityJ := assessPathQuality(allPaths[j], g)
		return qualityI > qualityJ
	})

	// Limit to maxPaths
	if len(allPaths) > maxPaths {
		allPaths = allPaths[:maxPaths]
	}

	return allPaths
}

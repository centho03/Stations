package graph

import (
	"sort"
)

// PathFinder handles finding multiple paths in a graph
type PathFinder struct {
	graph *Graph
}

// NewPathFinder creates a new PathFinder
func NewPathFinder(g *Graph) *PathFinder {
	return &PathFinder{graph: g}
}

// Path represents a sequence of stations
type Path []string

// FindMultiplePaths finds multiple paths from start to end
func (pf *PathFinder) FindMultiplePaths(start, end string, maxPaths int) []Path {
	allPaths := pf.findAllPaths(start, end, maxPaths*2) // Find more paths than needed
	
	// Sort paths by length
	sort.Slice(allPaths, func(i, j int) bool {
		return len(allPaths[i]) < len(allPaths[j])
	})
	
	// Select diverse paths
	selectedPaths := pf.selectDiversePaths(allPaths, maxPaths)
	
	return selectedPaths
}

// findAllPaths uses DFS to find all paths up to a limit
func (pf *PathFinder) findAllPaths(start, end string, limit int) []Path {
	var paths []Path
	visited := make(map[string]bool)
	currentPath := []string{}
	
	pf.dfs(start, end, visited, currentPath, &paths, limit)
	
	return paths
}

// dfs performs depth-first search to find paths
func (pf *PathFinder) dfs(current, end string, visited map[string]bool, currentPath []string, paths *[]Path, limit int) {
	if len(*paths) >= limit {
		return
	}
	
	visited[current] = true
	currentPath = append(currentPath, current)
	
	if current == end {
		// Found a path, make a copy and add it
		pathCopy := make([]string, len(currentPath))
		copy(pathCopy, currentPath)
		*paths = append(*paths, pathCopy)
	} else {
		// Explore neighbors
		node := pf.graph.Nodes[current]
		for _, neighbor := range node.Neighbors {
			if !visited[neighbor.Name] {
				pf.dfs(neighbor.Name, end, visited, currentPath, paths, limit)
			}
		}
	}
	
	// Backtrack
	visited[current] = false
}

// selectDiversePaths selects paths that share minimal nodes
func (pf *PathFinder) selectDiversePaths(allPaths []Path, maxPaths int) []Path {
	if len(allPaths) <= maxPaths {
		return allPaths
	}
	
	selected := []Path{}
	nodeUsage := make(map[string]int)
	
	for _, path := range allPaths {
		if len(selected) >= maxPaths {
			break
		}
		
		// Calculate overlap score
		overlapScore := 0
		for i := 1; i < len(path)-1; i++ { // Skip start and end
			overlapScore += nodeUsage[path[i]]
		}
		
		// Select paths with low overlap
		if len(selected) == 0 || overlapScore < len(path)/2 {
			selected = append(selected, path)
			// Update node usage
			for i := 1; i < len(path)-1; i++ {
				nodeUsage[path[i]]++
			}
		}
	}
	
	// If we don't have enough diverse paths, add shortest ones
	for _, path := range allPaths {
		if len(selected) >= maxPaths {
			break
		}
		
		found := false
		for _, s := range selected {
			if pathsEqual(path, s) {
				found = true
				break
			}
		}
		
		if !found {
			selected = append(selected, path)
		}
	}
	
	return selected
}

// pathsEqual checks if two paths are the same
func pathsEqual(a, b Path) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// BFS finds the shortest path between two nodes
func (pf *PathFinder) BFS(start, end string) Path {
	if start == end {
		return Path{start}
	}
	
	visited := make(map[string]bool)
	parent := make(map[string]string)
	queue := []string{start}
	visited[start] = true
	
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		
		node := pf.graph.Nodes[current]
		for _, neighbor := range node.Neighbors {
			if !visited[neighbor.Name] {
				visited[neighbor.Name] = true
				parent[neighbor.Name] = current
				queue = append(queue, neighbor.Name)
				
				if neighbor.Name == end {
					// Reconstruct path
					path := []string{}
					for n := end; n != ""; n = parent[n] {
						path = append([]string{n}, path...)
						if n == start {
							break
						}
					}
					return path
				}
			}
		}
	}
	
	return nil
}
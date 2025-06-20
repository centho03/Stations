package graph

import (
	"fmt"
	"math"

	"gitea.kood.tech/innocentkwizera1/stations/types"
)

// FlowNetwork represents a flow network for train pathfinding
type FlowNetwork struct {
	nodes    map[string]int // node name to index mapping
	nodeList []string       // index to node name mapping
	capacity [][]int        // capacity matrix
	flow     [][]int        // flow matrix
	n        int            // number of nodes
}

// AdvancedPathfinder uses max-flow algorithms for optimal train routing
type AdvancedPathfinder struct {
	network *types.Network
	graph   *Graph
}

func NewAdvancedPathfinder(network *types.Network) *AdvancedPathfinder {
	return &AdvancedPathfinder{
		network: network,
		graph:   BuildGraph(network),
	}
}

// FindOptimalPaths finds the optimal paths for multiple trains using max-flow
func (apf *AdvancedPathfinder) FindOptimalPaths(start, end string, numTrains int) [][]string {
	// First, try to find multiple shortest paths
	shortestPaths := apf.findMultipleShortestPaths(start, end, numTrains)
	
	if len(shortestPaths) >= numTrains {
		return shortestPaths[:numTrains]
	}
	
	// If we don't have enough paths, use flow-based approach
	return apf.findFlowBasedPaths(start, end, numTrains)
}

// findMultipleShortestPaths finds multiple shortest paths using node-disjoint and edge-disjoint approaches  
func (apf *AdvancedPathfinder) findMultipleShortestPaths(start, end string, maxPaths int) [][]string {
	paths := [][]string{}
	
	// Find the first shortest path
	firstPath := apf.graph.FindShortestPath(start, end)
	if firstPath == nil {
		return paths
	}
	
	paths = append(paths, firstPath)
	shortestLength := len(firstPath)
	
	// Try to find more paths by temporarily removing nodes/edges
	usedNodes := make(map[string]bool)
	usedEdges := make(map[string]bool)
	
	for len(paths) < maxPaths {
		bestPath := []string{}
		bestScore := math.MaxInt32
		
		// Try removing each intermediate node from existing paths
		for _, path := range paths {
			for i := 1; i < len(path)-1; i++ {
				if usedNodes[path[i]] {
					continue
				}
				
				tempGraph := apf.copyGraphWithoutNode(path[i])
				altPath := tempGraph.FindShortestPath(start, end)
				
				if altPath != nil && len(altPath) <= shortestLength+2 {
					score := apf.calculatePathScore(altPath, paths)
					if score < bestScore {
						bestPath = altPath
						bestScore = score
					}
				}
			}
		}
		
		// Try removing edges
		for _, path := range paths {
			for i := 0; i < len(path)-1; i++ {
				edgeKey := apf.getEdgeKey(path[i], path[i+1])
				if usedEdges[edgeKey] {
					continue
				}
				
				tempGraph := apf.copyGraphWithoutEdge(path[i], path[i+1])
				altPath := tempGraph.FindShortestPath(start, end)
				
				if altPath != nil && len(altPath) <= shortestLength+2 {
					score := apf.calculatePathScore(altPath, paths)
					if score < bestScore {
						bestPath = altPath
						bestScore = score
					}
				}
			}
		}
		
		if len(bestPath) == 0 {
			break
		}
		
		paths = append(paths, bestPath)
		
		// Mark nodes and edges as used
		for i := 1; i < len(bestPath)-1; i++ {
			usedNodes[bestPath[i]] = true
		}
		for i := 0; i < len(bestPath)-1; i++ {
			usedEdges[apf.getEdgeKey(bestPath[i], bestPath[i+1])] = true
		}
	}
	
	return paths
}

// findFlowBasedPaths uses max-flow to find optimal paths
func (apf *AdvancedPathfinder) findFlowBasedPaths(start, end string, numTrains int) [][]string {
	// Create time-expanded graph
	maxTime := apf.estimateMaxTime(start, end, numTrains)
	flowNet := apf.createTimeExpandedNetwork(start, end, maxTime)
	
	// Find maximum flow
	maxFlow := apf.dinicMaxFlow(flowNet, 0, flowNet.n-1)
	
	if maxFlow < numTrains {
		// Fallback to simple paths
		return apf.generateSimplePaths(start, end, numTrains)
	}
	
	// Decompose flow into paths
	return apf.decomposeFlowToPaths(flowNet, start, end, numTrains, maxTime)
}

// createTimeExpandedNetwork creates a time-expanded network for flow computation
func (apf *AdvancedPathfinder) createTimeExpandedNetwork(start, end string, maxTime int) *FlowNetwork {
	nodes := []string{}
	nodeMap := make(map[string]int)
	
	// Add source and sink
	nodes = append(nodes, "source", "sink")
	nodeMap["source"] = 0
	nodeMap["sink"] = 1
	
	// Add time-expanded nodes
	for station := range apf.network.Stations {
		for t := 0; t <= maxTime; t++ {
			nodeName := fmt.Sprintf("%s_%d", station, t)
			nodeMap[nodeName] = len(nodes)
			nodes = append(nodes, nodeName)
		}
	}
	
	n := len(nodes)
	capacity := make([][]int, n)
	for i := range capacity {
		capacity[i] = make([]int, n)
	}
	
	// Add edges from source to start stations at time 0
	startNode := nodeMap[fmt.Sprintf("%s_0", start)]
	capacity[0][startNode] = math.MaxInt32
	
	// Add edges from end stations to sink
	for t := 0; t <= maxTime; t++ {
		endNode := nodeMap[fmt.Sprintf("%s_%d", end, t)]
		capacity[endNode][1] = math.MaxInt32
	}
	
	// Add movement edges
	for station, neighbors := range apf.network.Connections {
		for t := 0; t < maxTime; t++ {
			currentNode := nodeMap[fmt.Sprintf("%s_%d", station, t)]
			
			// Stay at same station (if not intermediate)
			if station == start || station == end {
				nextNode := nodeMap[fmt.Sprintf("%s_%d", station, t+1)]
				capacity[currentNode][nextNode] = math.MaxInt32
			}
			
			// Move to neighboring stations
			for _, neighbor := range neighbors {
				nextNode := nodeMap[fmt.Sprintf("%s_%d", neighbor, t+1)]
				capacity[currentNode][nextNode] = 1 // Only one train per track per time
			}
		}
	}
	
	return &FlowNetwork{
		nodes:    nodeMap,
		nodeList: nodes,
		capacity: capacity,
		flow:     make([][]int, n),
		n:        n,
	}
}

// dinicMaxFlow implements Dinic's algorithm for maximum flow
func (apf *AdvancedPathfinder) dinicMaxFlow(fn *FlowNetwork, source, sink int) int {
	// Initialize flow matrix
	for i := range fn.flow {
		fn.flow[i] = make([]int, fn.n)
	}
	
	maxFlow := 0
	
	for apf.bfsLevel(fn, source, sink) {
		iter := make([]int, fn.n)
		for {
			pushed := apf.dfsFlow(fn, source, sink, math.MaxInt32, iter)
			if pushed == 0 {
				break
			}
			maxFlow += pushed
		}
	}
	
	return maxFlow
}

// bfsLevel builds level graph for Dinic's algorithm
func (apf *AdvancedPathfinder) bfsLevel(fn *FlowNetwork, source, sink int) bool {
	level := make([]int, fn.n)
	for i := range level {
		level[i] = -1
	}
	
	level[source] = 0
	queue := []int{source}
	
	for len(queue) > 0 {
		v := queue[0]
		queue = queue[1:]
		
		for to := 0; to < fn.n; to++ {
			if level[to] < 0 && fn.capacity[v][to]-fn.flow[v][to] > 0 {
				level[to] = level[v] + 1
				queue = append(queue, to)
			}
		}
	}
	
	return level[sink] >= 0
}

// dfsFlow performs DFS to find blocking flow
func (apf *AdvancedPathfinder) dfsFlow(fn *FlowNetwork, v, sink, pushed int, iter []int) int {
	if v == sink {
		return pushed
	}
	
	for iter[v] < fn.n {
		to := iter[v]
		if fn.capacity[v][to]-fn.flow[v][to] > 0 {
			tr := apf.dfsFlow(fn, to, sink, min(pushed, fn.capacity[v][to]-fn.flow[v][to]), iter)
			if tr > 0 {
				fn.flow[v][to] += tr
				fn.flow[to][v] -= tr
				return tr
			}
		}
		iter[v]++
	}
	
	return 0
}

// Helper functions
func (apf *AdvancedPathfinder) estimateMaxTime(start, end string, numTrains int) int {
	shortestPath := apf.graph.FindShortestPath(start, end)
	if shortestPath == nil {
		return numTrains * 10 // fallback
	}
	
	baseTime := len(shortestPath) - 1
	return baseTime + numTrains + 5 // Add buffer for congestion
}

func (apf *AdvancedPathfinder) calculatePathScore(path []string, existingPaths [][]string) int {
	score := len(path) * 100 // Base score on length
	
	// Penalize overlap with existing paths
	for _, existing := range existingPaths {
		overlap := apf.calculateOverlap(path, existing)
		score += overlap * 50
	}
	
	return score
}

func (apf *AdvancedPathfinder) calculateOverlap(path1, path2 []string) int {
	overlap := 0
	nodeSet := make(map[string]bool)
	
	for i := 1; i < len(path1)-1; i++ {
		nodeSet[path1[i]] = true
	}
	
	for i := 1; i < len(path2)-1; i++ {
		if nodeSet[path2[i]] {
			overlap++
		}
	}
	
	return overlap
}

func (apf *AdvancedPathfinder) copyGraphWithoutNode(excludeNode string) *Graph {
	newGraph := NewGraph()
	
	// Add all nodes except the excluded one
	for name := range apf.graph.Nodes {
		if name != excludeNode {
			newGraph.AddNode(name)
		}
	}
	
	// Add all edges not involving the excluded node
	for _, node := range apf.graph.Nodes {
		if node.Name != excludeNode {
			for _, neighbor := range node.Neighbors {
				if neighbor.Name != excludeNode {
					newGraph.AddEdge(node.Name, neighbor.Name)
				}
			}
		}
	}
	
	return newGraph
}

func (apf *AdvancedPathfinder) copyGraphWithoutEdge(from, to string) *Graph {
	newGraph := NewGraph()
	
	// Copy all nodes
	for name := range apf.graph.Nodes {
		newGraph.AddNode(name)
	}
	
	// Copy all edges except the specified one
	for _, node := range apf.graph.Nodes {
		for _, neighbor := range node.Neighbors {
			if !(node.Name == from && neighbor.Name == to) &&
				!(node.Name == to && neighbor.Name == from) {
				newGraph.AddEdge(node.Name, neighbor.Name)
			}
		}
	}
	
	return newGraph
}

func (apf *AdvancedPathfinder) getEdgeKey(from, to string) string {
	if from < to {
		return from + "-" + to
	}
	return to + "-" + from
}

func (apf *AdvancedPathfinder) generateSimplePaths(start, end string, numTrains int) [][]string {
	paths := [][]string{}
	shortestPath := apf.graph.FindShortestPath(start, end)
	
	if shortestPath == nil {
		return paths
	}
	
	// Generate paths with slight variations
	for i := 0; i < numTrains; i++ {
		if i < 3 {
			// Use different algorithms for first few paths
			path := apf.findAlternatePath(start, end, i)
			if path != nil {
				paths = append(paths, path)
			} else {
				paths = append(paths, shortestPath)
			}
		} else {
			paths = append(paths, shortestPath)
		}
	}
	
	return paths
}

func (apf *AdvancedPathfinder) findAlternatePath(start, end string, variant int) []string {
	// Try different approaches based on variant
	switch variant {
	case 0:
		return apf.graph.FindShortestPath(start, end)
	case 1:
		return apf.findSecondShortestPath(start, end)
	case 2:
		return apf.findLongestShortestPath(start, end)
	default:
		return apf.graph.FindShortestPath(start, end)
	}
}

func (apf *AdvancedPathfinder) findSecondShortestPath(start, end string) []string {
	firstPath := apf.graph.FindShortestPath(start, end)
	if firstPath == nil || len(firstPath) < 3 {
		return firstPath
	}
	
	// Try removing middle node
	middleNode := firstPath[len(firstPath)/2]
	tempGraph := apf.copyGraphWithoutNode(middleNode)
	return tempGraph.FindShortestPath(start, end)
}

func (apf *AdvancedPathfinder) findLongestShortestPath(start, end string) []string {
	// Find a path that's still relatively short but different
	bestPath := apf.graph.FindShortestPath(start, end)
	if bestPath == nil {
		return nil
	}
	
	shortestLen := len(bestPath)
	
	// Try all possible intermediate nodes
	for intermediate := range apf.network.Stations {
		if intermediate == start || intermediate == end {
			continue
		}
		
		path1 := apf.graph.FindShortestPath(start, intermediate)
		path2 := apf.graph.FindShortestPath(intermediate, end)
		
		if path1 != nil && path2 != nil {
			totalPath := append(path1[:len(path1)-1], path2...)
			if len(totalPath) <= shortestLen+2 && len(totalPath) > len(bestPath) {
				bestPath = totalPath
			}
		}
	}
	
	return bestPath
}

func (apf *AdvancedPathfinder) decomposeFlowToPaths(fn *FlowNetwork, start, end string, numTrains, maxTime int) [][]string {
	paths := [][]string{}
	
	// Simple path decomposition - for more complex cases, implement proper flow decomposition
	for i := 0; i < numTrains; i++ {
		path := apf.findPathInFlow(fn, start, end, maxTime)
		if path != nil {
			paths = append(paths, path)
		} else {
			// Fallback to shortest path
			shortestPath := apf.graph.FindShortestPath(start, end)
			if shortestPath != nil {
				paths = append(paths, shortestPath)
			}
		}
	}
	
	return paths
}

func (apf *AdvancedPathfinder) findPathInFlow(fn *FlowNetwork, start, end string, maxTime int) []string {
	// Simplified path extraction from flow network
	// In a complete implementation, this would trace actual flow paths
	return apf.graph.FindShortestPath(start, end)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
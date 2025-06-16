package simulation

import (
	"fmt"
	"sort"
	"strings"

	"gitea.kood.tech/innocentkwizera1/stations/errors"
	"gitea.kood.tech/innocentkwizera1/stations/graph"
)

func normalizeEdge(from, to string) string {
	if from < to {
		return from + "-" + to
	}
	return to + "-" + from
}

func SimulateTrains(g *graph.Graph, start, end string, numTrains int) {
	// Find all possible disjoint paths
	paths := FindDisjointPaths(g, start, end, 100)
	if len(paths) == 0 {
		errors.PrintError(errors.ErrNoPath)
		return
	}

	// Train structure
	type Train struct {
		id   int
		path []string
		pos  int
	}

	// Calculate optimal train distribution based on path lengths
	trains := make([]*Train, numTrains)
	
	if len(paths) == 1 {
		// Single path - all trains use it
		for i := 0; i < numTrains; i++ {
			trains[i] = &Train{
				id:   i + 1,
				path: paths[0],
				pos:  0,
			}
		}
	} else {
		// Multiple paths - distribute optimally
		// Calculate how many trains each path should get
		pathLengths := make([]int, len(paths))
		for i, path := range paths {
			pathLengths[i] = len(path) - 1
		}
		
		// Distribute trains to minimize total time
		trainCounts := distributeTrainsOptimally(pathLengths, numTrains)
		
		// Assign trains to paths
		trainIdx := 0
		for pathIdx, count := range trainCounts {
			for i := 0; i < count; i++ {
				trains[trainIdx] = &Train{
					id:   trainIdx + 1,
					path: paths[pathIdx],
					pos:  0,
				}
				trainIdx++
			}
		}
	}

	// Main simulation loop
	for turn := 1; turn <= 1000; turn++ {
		// Track what's occupied BEFORE any movement
		stationBefore := make(map[string]int)
		for _, t := range trains {
			if t.pos < len(t.path) {
				stationBefore[t.path[t.pos]]++
			}
		}
		
		// Track usage for this turn
		edgeUsed := make(map[string]bool)
		stationAfter := make(map[string]int)
		
		// Copy initial positions to after
		for station, count := range stationBefore {
			stationAfter[station] = count
		}
		
		// Sort trains: those further along move first
		trainsCopy := make([]*Train, len(trains))
		copy(trainsCopy, trains)
		
		sort.Slice(trainsCopy, func(i, j int) bool {
			t1, t2 := trainsCopy[i], trainsCopy[j]
			if t1.pos != t2.pos {
				return t1.pos > t2.pos
			}
			return t1.id < t2.id
		})
		
		// Try to move each train
		for _, t := range trainsCopy {
			// Skip if at end
			if t.pos >= len(t.path)-1 {
				continue
			}
			
			currentStation := t.path[t.pos]
			nextStation := t.path[t.pos+1]
			edge := normalizeEdge(currentStation, nextStation)
			
			// Can move if:
			// 1. Edge not used this turn
			// 2. Next station has capacity
			canMove := !edgeUsed[edge]
			
			if canMove {
				// Check station capacity
				// Intermediate stations can hold only 1 train
				if nextStation != start && nextStation != end {
					if stationAfter[nextStation] >= 1 {
						canMove = false
					}
				}
			}
			
			if canMove {
				// Move the train
				t.pos++
				edgeUsed[edge] = true
				stationAfter[currentStation]--
				stationAfter[nextStation]++
			}
		}
		
		// Generate output
		movements := []string{}
		for _, t := range trains {
			station := t.path[t.pos]
			movements = append(movements, fmt.Sprintf("T%d-%s", t.id, station))
		}
		
		// Sort by train ID
		sort.Slice(movements, func(i, j int) bool {
			var id1, id2 int
			fmt.Sscanf(movements[i], "T%d-", &id1)
			fmt.Sscanf(movements[j], "T%d-", &id2)
			return id1 < id2
		})
		
		fmt.Println(strings.Join(movements, " "))
		
		// Check if all done
		allDone := true
		for _, t := range trains {
			if t.pos < len(t.path)-1 {
				allDone = false
				break
			}
		}
		
		if allDone {
			break
		}
	}
}

// distributeTrainsOptimally calculates optimal train distribution across paths
func distributeTrainsOptimally(pathLengths []int, numTrains int) []int {
	n := len(pathLengths)
	trainCounts := make([]int, n)
	
	if n == 1 {
		trainCounts[0] = numTrains
		return trainCounts
	}
	
	// Binary search for the optimal completion time
	left, right := 1, numTrains + maxInSlice(pathLengths)
	
	for left < right {
		mid := (left + right) / 2
		
		// Check if we can complete in 'mid' turns
		totalTrains := 0
		for i, length := range pathLengths {
			// For a path of length L, we can send at most (mid - L + 1) trains
			maxTrainsForPath := mid - length + 1
			if maxTrainsForPath > 0 {
				trainCounts[i] = maxTrainsForPath
				totalTrains += maxTrainsForPath
			} else {
				trainCounts[i] = 0
			}
		}
		
		if totalTrains >= numTrains {
			// We can do it in 'mid' turns, try less
			right = mid
		} else {
			// Need more turns
			left = mid + 1
		}
	}
	
	// Distribute exactly numTrains using the found completion time
	totalTrains := 0
	for i, length := range pathLengths {
		maxTrainsForPath := left - length + 1
		if maxTrainsForPath > 0 {
			trainCounts[i] = maxTrainsForPath
			totalTrains += maxTrainsForPath
		} else {
			trainCounts[i] = 0
		}
	}
	
	// Adjust to use exactly numTrains
	if totalTrains > numTrains {
		// Remove excess trains from longest paths first
		indices := make([]int, n)
		for i := range indices {
			indices[i] = i
		}
		sort.Slice(indices, func(i, j int) bool {
			return pathLengths[indices[i]] > pathLengths[indices[j]]
		})
		
		excess := totalTrains - numTrains
		for _, i := range indices {
			if trainCounts[i] > 0 && excess > 0 {
				remove := minInt(trainCounts[i], excess)
				trainCounts[i] -= remove
				excess -= remove
			}
		}
	}
	
	return trainCounts
}

func maxInSlice(slice []int) int {
	max := slice[0]
	for _, v := range slice[1:] {
		if v > max {
			max = v
		}
	}
	return max
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
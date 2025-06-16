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
	// Find disjoint paths
	paths := FindDisjointPaths(g, start, end, numTrains)
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

	// Create trains and assign to paths
	trains := make([]*Train, numTrains)
	
	// Distribute trains across available paths
	for i := 0; i < numTrains; i++ {
		pathIdx := i % len(paths)
		trains[i] = &Train{
			id:   i + 1,
			path: paths[pathIdx],
			pos:  0,
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
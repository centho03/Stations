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

// Add this function after normalizeEdge function (around line 17)
func assignTrainsOptimally(paths [][]string, numTrains int) []int {
	if len(paths) == 0 {
		return []int{}
	}

	assignments := make([]int, numTrains)

	// Simple round-robin assignment
	for i := 0; i < numTrains; i++ {
		assignments[i] = (len(paths) - 1 - (i % len(paths)))
	}

	return assignments
}

type Train struct {
	id      int
	path    []string
	pos     int // index on path
	arrived bool
}

func SimulateTrains(g *graph.Graph, start, end string, numTrains int) {
	// 1. Find as many unique edge-disjoint paths as possible
	paths := FindDisjointPaths(g, start, end, numTrains)
	if len(paths) == 0 {
		errors.PrintError(errors.ErrNoPath)
		return
	}

	// 2. Init trains - all use the same path for now
	assignments := assignTrainsOptimally(paths, numTrains)

	trains := make([]*Train, numTrains)
	for i := 0; i < numTrains; i++ {
		pathIndex := assignments[i] // ← Now uses smart assignment
		trains[i] = &Train{
			id:   i + 1,
			path: paths[pathIndex],
			pos:  0,
		}
	}

	// 3. Simulate movement turn by turn
	allArrived := false
	for !allArrived {
		occupied := map[string]bool{}
		usedEdges := map[string]bool{}

		// Mark currently occupied stations (not start/end)
		for _, t := range trains {
			if t.pos > 0 && t.pos < len(t.path)-1 {
				occupied[t.path[t.pos]] = true
			}
		}

		// Sort trains by priority (closer to end = higher priority)
		trainOrder := make([]*Train, 0, len(trains))
		for _, t := range trains {
			if !t.arrived {
				trainOrder = append(trainOrder, t)
			}
		}

		// Sort by progress percentage (closer to end moves first)
		sort.Slice(trainOrder, func(i, j int) bool {
			progressI := float64(trainOrder[i].pos) / float64(len(trainOrder[i].path)-1)
			progressJ := float64(trainOrder[j].pos) / float64(len(trainOrder[j].path)-1)
			if progressI != progressJ {
				return progressI > progressJ
			}
			// If same progress, prioritize by train ID for consistency
			return trainOrder[i].id < trainOrder[j].id
		})

		// Move trains in priority order
		for _, t := range trainOrder {
			// Already at end
			if t.pos == len(t.path)-1 {
				t.arrived = true
				continue
			}

			nextPos := t.pos + 1
			nextStation := t.path[nextPos]
			edge := normalizeEdge(t.path[t.pos], nextStation)

			// Enhanced movement logic for optimal scheduling
			canMove := true

			// Special logic for single path scenarios - staggered starts
			if len(paths) == 1 {
				// Calculate how many trains should be moving simultaneously
				maxConcurrent := min(3, numTrains) // Allow up to 3 trains on path simultaneously

				// Count trains currently on the path (not at start)
				trainsOnPath := 0
				for _, otherTrain := range trains {
					if otherTrain.pos > 0 && !otherTrain.arrived {
						trainsOnPath++
					}
				}

				// If at start station, only allow movement if not too many trains on path
				if t.pos == 0 && trainsOnPath >= maxConcurrent {
					canMove = false
				}

				// Standard collision checks
				if usedEdges[edge] {
					canMove = false
				}

				if nextStation != end && occupied[nextStation] {
					canMove = false
				}
			} else {
				// Multi-path logic (your existing code)
				if usedEdges[edge] {
					canMove = false
				}

				if nextStation != end && occupied[nextStation] {
					canMove = false
				}
			}

			if canMove {
				// Move train
				t.pos = nextPos

				usedEdges[edge] = true

				// Check if arrived
				if nextStation == end {
					t.arrived = true
				}
			}
		}

		// Print this turn
		move := []string{}
		for _, t := range trains {
			where := t.path[t.pos]
			move = append(move, fmt.Sprintf("T%d-%s", t.id, where))
		}
		fmt.Println(strings.Join(move, " "))

		// Check if all have arrived
		allArrived = true
		for _, t := range trains {
			if !t.arrived {
				allArrived = false
				break
			}
		}
	}
}

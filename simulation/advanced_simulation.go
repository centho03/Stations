package simulation

import (
	"fmt"
	"sort"
	"strings"

	"gitea.kood.tech/innocentkwizera1/stations/graph"
	"gitea.kood.tech/innocentkwizera1/stations/types"
)

type AdvancedSimulator struct {
	network     *types.Network
	start       string
	end         string
	numTrains   int
	trains      []*types.Train
	pathfinder  *graph.AdvancedPathfinder
	scheduler   *TrainScheduler
}

type TrainScheduler struct {
	timeStep        int
	stationOccupied map[string]map[int]bool // station -> time -> occupied
	trackUsed       map[string]map[int]bool // track -> time -> used
}

func NewAdvancedSimulator(network *types.Network, start, end string, numTrains int) *AdvancedSimulator {
	return &AdvancedSimulator{
		network:     network,
		start:       start,
		end:         end,
		numTrains:   numTrains,
		trains:      make([]*types.Train, 0),
		pathfinder:  graph.NewAdvancedPathfinder(network),
		scheduler:   NewTrainScheduler(),
	}
}

func NewTrainScheduler() *TrainScheduler {
	return &TrainScheduler{
		timeStep:        0,
		stationOccupied: make(map[string]map[int]bool),
		trackUsed:       make(map[string]map[int]bool),
	}
}

func (as *AdvancedSimulator) Run() ([]string, error) {
	// Initialize trains
	as.initializeTrains()
	
	// Find optimal paths using advanced pathfinding
	paths := as.pathfinder.FindOptimalPaths(as.start, as.end, as.numTrains)
	
	// Assign paths to trains with load balancing
	as.assignPathsToTrains(paths)
	
	// Run advanced simulation with conflict resolution
	return as.simulateWithScheduling()
}

func (as *AdvancedSimulator) initializeTrains() {
	for i := 1; i <= as.numTrains; i++ {
		train := &types.Train{
			ID:       i,
			Name:     fmt.Sprintf("T%d", i),
			Position: as.start,
			Path:     []string{},
			PathPos:  0,
		}
		as.trains = append(as.trains, train)
	}
}

func (as *AdvancedSimulator) assignPathsToTrains(paths [][]string) {
	if len(paths) == 0 {
		return
	}
	
	// Sort paths by length (shorter paths first)
	sort.Slice(paths, func(i, j int) bool {
		return len(paths[i]) < len(paths[j])
	})
	
	// Assign paths to trains with load balancing
	pathUsage := make([]int, len(paths))
	
	for i, train := range as.trains {
		// Find the least used path
		bestPathIdx := 0
		for j, usage := range pathUsage {
			if usage < pathUsage[bestPathIdx] {
				bestPathIdx = j
			}
		}
		
		// If we have fewer paths than trains, distribute evenly
		if i < len(paths) {
			train.Path = make([]string, len(paths[i]))
			copy(train.Path, paths[i])
		} else {
			pathIdx := i % len(paths)
			train.Path = make([]string, len(paths[pathIdx]))
			copy(train.Path, paths[pathIdx])
		}
		
		pathUsage[bestPathIdx]++
	}
}

func (as *AdvancedSimulator) simulateWithScheduling() ([]string, error) {
	moves := []string{}
	turn := 0
	maxTurns := as.calculateMaxTurns()
	
	for !as.allTrainsAtDestination() && turn < maxTurns {
		turn++
		as.scheduler.timeStep = turn
		
		turnMoves := as.executeTurn()
		
		if len(turnMoves) > 0 {
			moves = append(moves, strings.Join(turnMoves, " "))
		}
	}
	
	if turn >= maxTurns {
		return moves, fmt.Errorf("simulation exceeded maximum turns")
	}
	
	return moves, nil
}

func (as *AdvancedSimulator) executeTurn() []string {
	var trainMoves []TrainMove
	
	// Create priority queue for train movements
	candidates := as.generateMoveCandidates()
	
	// Sort candidates by priority (distance to destination, train ID, etc.)
	sort.Slice(candidates, func(i, j int) bool {
		return as.compareMoves(candidates[i], candidates[j])
	})
	
	// Execute moves in priority order
	usedTracks := make(map[string]bool)
	occupiedStations := as.getCurrentOccupiedStations()
	
	for _, candidate := range candidates {
		if as.canExecuteMove(candidate, usedTracks, occupiedStations) {
			as.executeMove(candidate)
			trainMoves = append(trainMoves, TrainMove{
				TrainName: candidate.train.Name,
				To:        candidate.nextStation,
			})
			
			// Update tracking
			track := as.getTrackKey(candidate.train.Position, candidate.nextStation)
			usedTracks[track] = true
			
			if candidate.nextStation != as.end {
				occupiedStations[candidate.nextStation] = true
			}
			if candidate.train.Position != as.start {
				delete(occupiedStations, candidate.train.Position)
			}
		}
	}
	
	// Convert to string format
	moveStrings := make([]string, len(trainMoves))
	for i, move := range trainMoves {
		moveStrings[i] = move.String()
	}
	
	return moveStrings
}

type MoveCandidate struct {
	train       *types.Train
	nextStation string
	priority    int
}

func (as *AdvancedSimulator) generateMoveCandidates() []MoveCandidate {
	var candidates []MoveCandidate
	
	for _, train := range as.trains {
		if train.Position == as.end {
			continue
		}
		
		// Check if train can move to next station in path
		if train.PathPos+1 < len(train.Path) {
			nextStation := train.Path[train.PathPos+1]
			priority := as.calculateMovePriority(train, nextStation)
			
			candidates = append(candidates, MoveCandidate{
				train:       train,
				nextStation: nextStation,
				priority:    priority,
			})
		}
	}
	
	return candidates
}

func (as *AdvancedSimulator) calculateMovePriority(train *types.Train, nextStation string) int {
	priority := 0
	
	// Higher priority for trains closer to destination
	remainingSteps := len(train.Path) - train.PathPos - 1
	priority += (1000 - remainingSteps*10)
	
	// Higher priority for lower train IDs (consistent ordering)
	priority += (1000 - train.ID)
	
	// Bonus for moving to destination
	if nextStation == as.end {
		priority += 500
	}
	
	return priority
}

func (as *AdvancedSimulator) compareMoves(a, b MoveCandidate) bool {
	return a.priority > b.priority
}

func (as *AdvancedSimulator) getCurrentOccupiedStations() map[string]bool {
	occupied := make(map[string]bool)
	
	for _, train := range as.trains {
		if train.Position != as.start && train.Position != as.end {
			occupied[train.Position] = true
		}
	}
	
	return occupied
}

func (as *AdvancedSimulator) canExecuteMove(candidate MoveCandidate, usedTracks, occupiedStations map[string]bool) bool {
	track := as.getTrackKey(candidate.train.Position, candidate.nextStation)
	
	// Check if track is available
	if usedTracks[track] {
		return false
	}
	
	// Check if destination is available (except for end station)
	if candidate.nextStation != as.end && occupiedStations[candidate.nextStation] {
		return false
	}
	
	return true
}

func (as *AdvancedSimulator) executeMove(candidate MoveCandidate) {
	candidate.train.Position = candidate.nextStation
	candidate.train.PathPos++
}

func (as *AdvancedSimulator) calculateMaxTurns() int {
	// Estimate maximum turns needed
	shortestPathLen := 0
	if len(as.trains) > 0 && len(as.trains[0].Path) > 0 {
		shortestPathLen = len(as.trains[0].Path) - 1
	}
	
	// Conservative estimate: base path length + congestion factor
	maxTurns := shortestPathLen + as.numTrains + 10
	
	// Cap at reasonable maximum
	if maxTurns > 1000 {
		maxTurns = 1000
	}
	
	return maxTurns
}

func (as *AdvancedSimulator) allTrainsAtDestination() bool {
	for _, train := range as.trains {
		if train.Position != as.end {
			return false
		}
	}
	return true
}

func (as *AdvancedSimulator) getTrackKey(from, to string) string {
	if from < to {
		return from + "-" + to
	}
	return to + "-" + from
}

// TrainMove represents a single train movement
type TrainMove struct {
	TrainName string
	To        string
}

func (tm TrainMove) String() string {
	return fmt.Sprintf("%s-%s", tm.TrainName, tm.To)
}
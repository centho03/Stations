package validation

import (
	"strconv"

	"gitea.kood.tech/innocentkwizera1/stations/errors"
	"gitea.kood.tech/innocentkwizera1/stations/graph"
	"gitea.kood.tech/innocentkwizera1/stations/parser"
	"gitea.kood.tech/innocentkwizera1/stations/types"
)

// argument parsing, validation and returning parsed data
func ValidateAndLoad(args []string) (*types.Network, string, string, int, error) {

	mapFile := args[1]
	start := args[2]
	end := args[3]
	numTrainsStr := args[4]

	numTrains, err := strconv.Atoi(numTrainsStr)
	if err != nil || numTrains <= 0 {
		return nil, "", "", 0, errors.ErrInvalidTrainCount
	}

	network, err := parser.ParseFile(mapFile)
	if err != nil {
		return nil, "", "", 0, err
	}

	if _, ok := network.Stations[start]; !ok {
		return nil, "", "", 0, errors.ErrStartStationNotFound
	}

	if _, ok := network.Stations[end]; !ok {
		return nil, "", "", 0, errors.ErrEndStationNotFound
	}

	if start == end {
		return nil, "", "", 0, errors.ErrSameStartAndEnd
	}

	// Enhanced validation: Check if path exists
	g := &graph.Graph{Nodes: make(map[string]*graph.Node)}
	for name := range network.Stations {
		g.AddNode(name)
	}
	for from, neighbors := range network.Connections {
		for _, to := range neighbors {
			g.AddEdge(from, to)
		}
	}

	// Verify path exists between start and end
	if !g.PathExists(start, end) {
		return nil, "", "", 0, errors.ErrNoPath
	}

	// Validate train count limits
	if numTrains > 10000 {
		return nil, "", "", 0, errors.ErrInvalidTrainCount
	}

	return network, start, end, numTrains, nil
}

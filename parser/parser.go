package parser

import (
	"bufio"
	"os"
	"strconv"
	"strings"

	"gitea.kood.tech/innocentkwizera1/stations/errors"
	"gitea.kood.tech/innocentkwizera1/stations/types"
)

func ParseFile(path string) (*types.Network, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	network := types.NewNetwork()
	scanner := bufio.NewScanner(file)
	hasStations := false
	hasConnections := false
	inStations := false
	inConnections := false
	lineNum := 0
	
	// Using a map is a more reliable way to track existing connections
	// to prevent duplicates like 'a-b' and 'b-a'.
	connectionSet := make(map[string]bool)

	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if idx := strings.Index(line, "#"); idx != -1 {
			line = strings.TrimSpace(line[:idx])
		}

		if line == "stations:" {
			hasStations = true
			inStations = true
			inConnections = false
			continue
		}
		if line == "connections:" {
			hasConnections = true
			inStations = false
			inConnections = true
			continue
		}

		if inStations {
			parts := strings.Split(line, ",")
			if len(parts) != 3 {
				return nil, errors.ErrInvalidStationFormat
			}

			name := strings.TrimSpace(parts[0])
			if name == "" || strings.ContainsAny(name, " ,-") { // Stricter name validation
				return nil, errors.ErrInvalidStationFormat 
			}
			xStr := strings.TrimSpace(parts[1])
			yStr := strings.TrimSpace(parts[2])

			x, errX := strconv.Atoi(xStr)
			y, errY := strconv.Atoi(yStr)

			if errX != nil || errY != nil || x < 0 || y < 0 {
				return nil, errors.ErrInvalidCoords
			}

			if _, exists := network.Stations[name]; exists {
				return nil, errors.ErrDuplicateStation
			}

			for _, s := range network.Stations {
				if s.X == x && s.Y == y {
					return nil, errors.ErrDuplicateCoords
				}
			}

			network.Stations[name] = &types.Station{Name: name, X: x, Y: y}
			if len(network.Stations) > 10000 {
				return nil, errors.ErrMapTooLarge
			}
		} else if inConnections {
			parts := strings.Split(line, "-")
			if len(parts) != 2 {
				return nil, errors.ErrInvalidConnection
			}

			from := strings.TrimSpace(parts[0])
			to := strings.TrimSpace(parts[1])

			if from == "" || to == "" {
				return nil, errors.ErrInvalidConnection
			}

			if _, ok := network.Stations[from]; !ok {
				return nil, errors.ErrInvalidConnection
			}
			if _, ok := network.Stations[to]; !ok {
				return nil, errors.ErrInvalidConnection
			}

			// To check for duplicates, we create a canonical key.
			// 'a-b' and 'b-a' will both result in the same key "a-b" if 'a' comes before 'b'.
			key := from + "-" + to
			if from > to {
				key = to + "-" + from
			}

			if connectionSet[key] {
				return nil, errors.ErrDuplicateConnection
			}
			connectionSet[key] = true

			// Add the connection both ways to the main network struct
			network.Connections[from] = append(network.Connections[from], to)
			network.Connections[to] = append(network.Connections[to], from)

		} else if hasStations && hasConnections {
			// Ignore lines that might be after the main sections
			continue
		} else {
			return nil, errors.ErrMissingSections
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}
	if !hasStations || !hasConnections {
		return nil, errors.ErrMissingSections
	}
	return network, nil
}

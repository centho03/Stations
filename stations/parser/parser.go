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

	inStations := false
	inConnections := false

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if idx := strings.Index(line, "#"); idx != -1 {
			line = strings.TrimSpace(line[:idx])
		}

		if line == "stations:" {
			inStations = true
			inConnections = false
			continue
		}
		if line == "connections:" {
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
			xStr := strings.TrimSpace(parts[1])
			yStr := strings.TrimSpace(parts[2])

			x, errX := strconv.Atoi(xStr)
			y, errY := strconv.Atoi(yStr)

			if errX != nil || errY != nil || x <= 0 || y <= 0 {
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
		} else if inConnections {
			parts := strings.Split(line, "-")
			if len(parts) != 2 {
				return nil, errors.ErrInvalidConnection
			}

			from := strings.TrimSpace(parts[0])
			to := strings.TrimSpace(parts[1])

			if _, ok := network.Stations[from]; !ok {
				return nil, errors.ErrInvalidConnection
			}
			if _, ok := network.Stations[to]; !ok {
				return nil, errors.ErrInvalidConnection
			}

			if hasConnection(network.Connections[from], to) || hasConnection(network.Connections[to], from) {
				return nil, errors.ErrDuplicateConnection
			}

			network.Connections[from] = append(network.Connections[from], to)
			network.Connections[to] = append(network.Connections[to], from)
		} else {
			return nil, errors.ErrMissingSections
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return network, nil
}

func hasConnection(list []string, target string) bool {
	for _, v := range list {
		if v == target {
			return true
		}
	}
	return false
}

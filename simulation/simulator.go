package simulation

import (
	"gitea.kood.tech/innocentkwizera1/stations/types"
)

// NewSimulator creates and returns an AdvancedSimulator for better performance
func NewSimulator(network *types.Network, start, end string, numTrains int) *AdvancedSimulator {
	return NewAdvancedSimulator(network, start, end, numTrains)
}
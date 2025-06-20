package main

import (
	"fmt"
	"os"

	"gitea.kood.tech/innocentkwizera1/stations/errors"
	"gitea.kood.tech/innocentkwizera1/stations/simulation"
	"gitea.kood.tech/innocentkwizera1/stations/validation"
)

func main() {
	if len(os.Args) < 5 {
		errors.PrintError(errors.ErrTooFewArgs)
		os.Exit(1)
	}
	if len(os.Args) > 5 {
		errors.PrintError(errors.ErrTooManyArgs)
		os.Exit(1)
	}

	network, start, end, numTrains, err := validation.ValidateAndLoad(os.Args)
	if err != nil {
		errors.PrintError(err)
		os.Exit(1)
	}

	simulator := simulation.NewSimulator(network, start, end, numTrains)
	moves, err := simulator.Run()
	if err != nil {
		errors.PrintError(err)
		os.Exit(1)
	}

	for _, move := range moves {
		fmt.Println(move)
	}
}
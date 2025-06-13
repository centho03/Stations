package errors

import (
	"errors"
	"fmt"
	"os"
)

var (
	ErrMissingSections      = errors.New("missing 'stations:' or 'connections:' section")
	ErrInvalidStationFormat = errors.New("invalid station format")
	ErrInvalidCoords        = errors.New("coordinates must be positive integers")
	ErrDuplicateStation     = errors.New("duplicate station name")
	ErrDuplicateCoords      = errors.New("duplicate coordinates")
	ErrInvalidConnection    = errors.New("connection includes a non-existent station")
	ErrDuplicateConnection  = errors.New("duplicate connection")
	ErrSameStartAndEnd      = errors.New("start and end station cannot be the same")
	ErrNoPath               = errors.New("no path exists between start and end stations")
	ErrTooFewArgs           = errors.New("too few command line arguments")
	ErrTooManyArgs          = errors.New("too many command line arguments")
	ErrInvalidTrainCount    = errors.New("invalid number of trains")
	ErrStartStationNotFound = errors.New("start station does not exist")
	ErrEndStationNotFound   = errors.New("end station does not exist")
	ErrMapTooLarge         = errors.New("map contains more than 10000 stations")
)

func PrintError(err error) {
	fmt.Fprintln(os.Stderr, "Error:", err)
}

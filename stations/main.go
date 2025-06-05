package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"gitea.kood.tech/innocentkwizera1/stations/graph"
	"gitea.kood.tech/innocentkwizera1/stations/parser"
)

func main() {
	g := graph.NewGraph()
	scanner := bufio.NewScanner(os.Stdin)

	fmt.Println("Wlecome to the Station Network CLI!")
	fmt.Println("Commans: addstation, addedge, list, path, help, exit")

	for {
		fmt.Print("\n>")
		if !scanner.Scan() {
			break
		}
		input := scanner.Text()
		args := strings.Fields(input)
		if len(args) == 0 {
			continue
		}

		switch args[0] {
		case "load":
			if len(args) < 2 {
				fmt.Println("Usage: load [filename]")
				continue
			}
			net, err := parser.ParseFile(args[1])
			if err != nil {
				fmt.Println("Error loading file:", err)
				continue
			}
			g = graph.NewGraph()
			for name := range net.Stations {
				g.AddNode(name)
			}
			for from, tos := range net.Connections {
				for _, to := range tos {
					g.AddEdge(from, to)
				}
			}
			fmt.Printf("Loaded network from %s\n", args[1])

		case "addstation":
			if len(args) < 2 {
				fmt.Println("Usage: addstation {station_name}")
				continue
			}
			g.AddNode(args[1])
			fmt.Println("Added station:", args[1])
		case "addedge":
			if len(args) < 3 {
				fmt.Println("Usage: addedge [station1] [station2]")
				continue
			}
			g.AddEdge(args[1], args[2])
			fmt.Printf("Connected %s and %s\n", args[1], args[2])
		case "list":
			if len(g.Nodes) == 0 {
				fmt.Println("No stations in the network.")
				continue
			}
			for name, node := range g.Nodes {
				fmt.Printf("%s: %v\n", name, node.Neighbors)
			}

		case "path":
			if len(args) < 3 {
				fmt.Println("Usage: path[start_station] [end_station]")
				continue
			}
			path := g.ShortestPath(args[1], args[2])
			if path == nil {
				fmt.Printf("No path found between %s and %s.\n", args[1], args[2])
			} else {
				fmt.Printf("Shortest path: %v", path)
			}
		case "help":
			fmt.Println("Commands:")
			fmt.Println("  addstation [station_name]")
			fmt.Println("  addedge [station1] [station2]")
			fmt.Println("  list")
			fmt.Println("  path [start_station] [end_station]")
			fmt.Println("  help")
			fmt.Println("  exit")

		case "exit":
			fmt.Println("Goodbye !")
			return

		default:
			fmt.Println("Unknown command. Type 'help' for a list of commands.")
		}

	}
}

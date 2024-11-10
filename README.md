# bootcamp-tools
This repo contains useful tools for development and operations.

## Tools Available

### Docker System Prune Wrapper
A flexible Docker cleanup utility that helps manage Docker resources efficiently.

Features:
- Selective pruning of containers, images, volumes, networks, or all resources
- Pattern-based filtering for targeted cleanup
- Dry-run mode to preview changes
- Logging capability for audit trails
- Force-stop option for running containers
- Color-coded output for better visibility

Usage:

sudo ./docker_system_prune.sh [OPTIONS]

Options:
- -o, --object     Object to prune (containers, images, volumes, networks, all)
- -p, --pattern    Pattern to filter objects (optional)
- -f, --force-stop Force stop running containers before pruning (optional)
- -d, --dry-run    Show what would be pruned without actually pruning (optional)
- -l, --log        Enable logging to file (optional)
- -h, --help       Show this help message and exit (optional)

Examples:
- ./docker_system_prune.sh -o containers -p "myapp" -f -d -l # Prune containers with "myapp" in their name
- ./docker_system_prune.sh -o all -f -l # Prune all resources, logging to file
- ./docker_system_prune.sh -o images -p "myimage:*" -d # Show what would be pruned without actually pruning


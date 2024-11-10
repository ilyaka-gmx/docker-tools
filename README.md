# bootcamp-tools
This repo contains useful tools for development and operations.

# bootcamp-tools

This repo contains useful tools for development and operations.

## Tools Available


### Docker System Prune Wrapper

A flexible Docker cleanup utility that helps manage Docker resources efficiently.

#### Features

* Selective pruning of containers, images, volumes, networks, or all resources
* Pattern-based filtering for targeted cleanup
* Dry-run mode to preview changes
* Logging capability for audit trails
* Force-stop option for running containers
* Color-coded output for better visibility

#### Usage

```bash
sudo ./docker_system_prune.sh [OPTIONS]
```

#### Options

| Option | Description | Example |
| --- | --- | --- |
| `-o, --object` | Object to prune (containers, images, volumes, networks, all) | `-o containers` |
| `-p, --pattern` | Pattern to filter objects (optional) | `-p "myapp"` |
| `-f, --force-stop` | Force stop running containers before pruning (optional) | `-f` |
| `-d, --dry-run` | Show what would be pruned without actually pruning (optional) | `-d` |
| `-l, --log` | Enable logging to file (optional) | `-l` |
| `-h, --help` | Show this help message and exit (optional) | `-h` |

#### Examples

### Prune Containers with Pattern

```bash
./docker_system_prune.sh -o containers -p "myapp" -f -d -l
```

### Prune All Resources with Force-Stop and Logging

```bash
./docker_system_prune.sh -o all -f -l
```

### Dry-Run Prune Images with Pattern

```bash
./docker_system_prune.sh -o images -p "myimage:*" -d
```
#!/bin/bash

# Docker System Prune Wrapper Script
# Provides flexible pruning with additional features

# Color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default configuration
FORCE_STOP=false
DRY_RUN_MODE=false
LOG_FILE="/var/log/docker_system_prune.log"
LOG_ENABLED=false
PATTERN=""
PRUNE_OBJECT=""

# Function to handle critical errors
handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    
    if [ "$LOG_ENABLED" = true ]; then
        log_message "${RED}ERROR: $error_message${NC}" "ERROR"
    fi
    echo -e "${RED}ERROR: $error_message${NC}"
    exit "$exit_code"
}

# Function to log messages
log_message() {
    local message="$1"
    local log_level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    if [ "$LOG_ENABLED" = true ]; then
        echo "[$timestamp] [$log_level] $message" >> "$LOG_FILE"
    fi
    echo -e "$message"
}

# Function to display script usage
usage() {
    echo "Docker System Prune Wrapper Script"
    echo "Usage: sudo $0 [OPTIONS]"
    echo "Options:"
    echo "  -o, --object     Object to prune (containers, images, volumes, networks, all)"
    echo "  -p, --pattern    Pattern to filter objects (optional)"
    echo "  -f, --force-stop Force stop running containers before pruning"
    echo "  -d, --dry-run    Show what would be pruned without actually pruning"
    echo "  -l, --log        Enable logging to file"
    echo "  -h, --help       Show this help message and exit"
    echo ""
    echo "Only objects parameter is mandatory, other parameters are optional."
    echo ""
    echo "Examples:"
    echo "  $0 -o containers          # Prune all containers"
    echo "  $0 -o images -p 'web'     # Prune images with 'web' in their name"
    echo "  $0 -o all -f              # Prune all resources with force stop"
}

# Function to stop running containers with pattern support
stop_containers() {
    local pattern="$1"
    local filter_cmd="status=running"
    
    if [ -n "$pattern" ]; then
        filter_cmd="$filter_cmd --filter name=$pattern"
    fi
    
    local running_containers=$(docker ps --filter "$filter_cmd" -q)
    if [ -n "$running_containers" ]; then
        if [ "$DRY_RUN_MODE" = true ]; then
            log_message "${YELLOW}DRY-RUN: Would stop containers: $(docker ps --filter "$filter_cmd" --format '{{.Names}}')${NC}"
        else
            log_message "${YELLOW}Stopping containers: $(docker ps --filter "$filter_cmd" --format '{{.Names}}')${NC}"
            docker stop $running_containers
        fi
    fi
}

# Function to prune containers with pattern support
prune_containers() {
    local pattern="$1"
    if [ -n "$pattern" ]; then
        local containers=$(docker ps -a --filter "name=$pattern" -q)
        if [ -n "$containers" ]; then
            if [ "$DRY_RUN_MODE" = true ]; then
                log_message "${YELLOW}DRY-RUN: Would remove containers: $(docker ps -a --filter "name=$pattern" --format '{{.Names}}')${NC}"
            else
                docker rm $containers
            fi
        fi
    else
        if [ "$DRY_RUN_MODE" = true ]; then
            log_message "${YELLOW}DRY-RUN: Would prune all stopped containers${NC}"
        else
            docker container prune -f
        fi
    fi
}

# Function to prune images with pattern support
prune_images() {
    local pattern="$1"
    if [ -n "$pattern" ]; then
        local images=$(docker images "*${pattern}*" --format '{{.ID}}')
        if [ -n "$images" ]; then
            if [ "$DRY_RUN_MODE" = true ]; then
                log_message "${YELLOW}DRY-RUN: Would remove images: $(docker images "*${pattern}*" --format '{{.Repository}}:{{.Tag}}')${NC}"
            else
                docker rmi $images
            fi
        fi
    else
        if [ "$DRY_RUN_MODE" = true ]; then
            log_message "${YELLOW}DRY-RUN: Would prune all unused images${NC}"
        else
            docker image prune -a -f
        fi
    fi
}

# Function to prune volumes with pattern support
prune_volumes() {
    local pattern="$1"
    if [ -n "$pattern" ]; then
        local volumes=$(docker volume ls -q | grep "$pattern")
        if [ -n "$volumes" ]; then
            if [ "$DRY_RUN_MODE" = true ]; then
                log_message "${YELLOW}DRY-RUN: Would remove volumes: $volumes${NC}"
            else
                echo "$volumes" | xargs docker volume rm
            fi
        fi
    else
        if [ "$DRY_RUN_MODE" = true ]; then
            log_message "${YELLOW}DRY-RUN: Would prune all unused volumes${NC}"
        else
            docker volume prune -f
        fi
    fi
}

# Function to prune networks with pattern support
prune_networks() {
    local pattern="$1"
    if [ -n "$pattern" ]; then
        local networks=$(docker network ls --filter "name=$pattern" -q)
        if [ -n "$networks" ]; then
            if [ "$DRY_RUN_MODE" = true ]; then
                log_message "${YELLOW}DRY-RUN: Would remove networks: $(docker network ls --filter "name=$pattern" --format '{{.Name}}')${NC}"
            else
                docker network rm $networks
            fi
        fi
    else
        if [ "$DRY_RUN_MODE" = true ]; then
            log_message "${YELLOW}DRY-RUN: Would prune all unused networks${NC}"
        else
            docker network prune -f
        fi
    fi
}

# Function to perform system prune
system_prune() {
    local object="$1"
    local pattern="$2"
    
    case "$object" in
        containers)
            if [ "$FORCE_STOP" = true ]; then
                stop_containers "$pattern"
            fi
            prune_containers "$pattern"
            ;;
        images)
            prune_images "$pattern"
            ;;
        volumes)
            prune_volumes "$pattern"
            ;;
        networks)
            prune_networks "$pattern"
            ;;
        all)
            if [ "$FORCE_STOP" = true ]; then
                stop_containers "$pattern"
            fi
            prune_containers "$pattern"
            prune_images "$pattern"
            prune_volumes "$pattern"
            prune_networks "$pattern"
            ;;
        *)
            handle_error "Invalid prune object: $object"
            ;;
    esac
}

# Main script logic
main() {
    if ! command -v docker &> /dev/null; then
        handle_error "Docker is not installed"
    fi

    local ARGS
    ARGS=$(getopt -o o:p:fdlh -l object:,pattern:,force-stop,dry-run,log,help -n "$0" -- "$@")

    if [ $? -ne 0 ]; then
        usage
        exit 1
    fi

    eval set -- "$ARGS"

    while true; do
        case "$1" in
            -o|--object)
                PRUNE_OBJECT="$2"
                shift 2 ;;
            -p|--pattern)
                PATTERN="$2"
                shift 2 ;;
            -f|--force-stop)
                FORCE_STOP=true
                shift ;;
            -d|--dry-run)
                DRY_RUN_MODE=true
                shift ;;
            -l|--log)
                LOG_ENABLED=true
                mkdir -p "$(dirname "$LOG_FILE")" || handle_error "Could not create log directory"
                shift ;;
            -h|--help)
                usage
                exit 0 ;;
            --)
                shift
                break ;;
            *)
                usage
                exit 1 ;;
        esac
    done

    if [ -z "$PRUNE_OBJECT" ]; then
        # handle_error "Prune object is required"
        usage
        exit 1
    fi

    system_prune "$PRUNE_OBJECT" "$PATTERN"
}

# Run the main script
main "$@"
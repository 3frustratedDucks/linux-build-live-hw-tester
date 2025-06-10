#!/bin/bash

# hw-test.sh
# A comprehensive hardware testing script for live USB environments
# Author: Michael
# Version: 1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_CPU_TEST_TIME=300  # 5 minutes
DEFAULT_MEM_TEST_TIME=300  # 5 minutes
DEFAULT_DISK_TEST_TIME=600 # 10 minutes
KEYBOARD_TEST_TIME=60      # 1 minute

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This operation requires root privileges${NC}"
        echo -e "${YELLOW}Please run this script with sudo${NC}"
        return 1
    fi
    return 0
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for required commands
check_requirements() {
    local missing_commands=()
    
    # Check for stress-ng
    if ! command_exists stress-ng; then
        missing_commands+=("stress-ng")
    fi
    
    # Check for memtester
    if ! command_exists memtester; then
        missing_commands+=("memtester")
    fi
    
    # Check for smartctl
    if ! command_exists smartctl; then
        missing_commands+=("smartctl")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        echo -e "${RED}Missing required commands:${NC}"
        for cmd in "${missing_commands[@]}"; do
            echo -e "${YELLOW}- $cmd${NC}"
        done
        echo -e "${YELLOW}Please install the missing commands and try again${NC}"
        return 1
    fi
    
    return 0
}

# Get system information
get_system_info() {
    clear
    echo -e "${GREEN}=== System Information ===${NC}"
    echo
    
    # CPU Information
    echo -e "${YELLOW}CPU:${NC}"
    lscpu | grep -E "Model name|Socket|Thread|Core|CPU\(s\)"
    echo
    
    # Memory Information
    echo -e "${YELLOW}Memory:${NC}"
    free -h
    echo
    
    # Disk Information
    echo -e "${YELLOW}Disk:${NC}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    echo
    
    # Battery Information
    if [ -d "/sys/class/power_supply" ]; then
        echo -e "${YELLOW}Battery:${NC}"
        for battery in /sys/class/power_supply/BAT*; do
            if [ -d "$battery" ]; then
                echo "Battery: $(basename $battery)"
                echo "Status: $(cat $battery/status)"
                echo "Capacity: $(cat $battery/capacity)%"
                if [ -f "$battery/health" ]; then
                    echo "Health: $(cat $battery/health)"
                fi
                echo
            fi
        done
    fi
    
    # Network Interfaces
    echo -e "${YELLOW}Network Interfaces:${NC}"
    ip -o link show | awk -F': ' '{print $2}'
    echo
    
    # Temperature Information
    if command -v sensors &> /dev/null; then
        echo -e "${YELLOW}Temperatures:${NC}"
        sensors
    fi
}

# CPU Stress Test
run_cpu_test() {
    local duration=$1
    
    # Check for stress-ng
    if ! command_exists stress-ng; then
        echo -e "${RED}stress-ng is not installed${NC}"
        echo -e "${YELLOW}Please install it and try again${NC}"
        return 1
    fi
    
    local cpu_count=$(nproc)
    local workers=$((cpu_count * 2))
    
    echo -e "${GREEN}Starting CPU stress test for ${duration} seconds${NC}"
    echo "Using $workers workers on $cpu_count CPUs"
    
    stress-ng --cpu $workers --timeout $duration --metrics
}

# Memory Test
run_memory_test() {
    local duration=$1
    
    # Check for memtester
    if ! command_exists memtester; then
        echo -e "${RED}memtester is not installed${NC}"
        echo -e "${YELLOW}Please install it and try again${NC}"
        return 1
    fi
    
    # Check for root privileges
    if ! check_root; then
        return 1
    fi
    
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local test_mem=$((total_mem / 2))  # Use half of available memory
    
    echo -e "${GREEN}Starting memory test for ${duration} seconds${NC}"
    echo "Testing $test_mem MB of memory"
    
    memtester $test_mem 1
}

# Disk Test
run_disk_test() {
    local duration=$1
    
    # Check for smartctl
    if ! command_exists smartctl; then
        echo -e "${RED}smartctl is not installed${NC}"
        echo -e "${YELLOW}Please install it and try again${NC}"
        return 1
    fi
    
    # Check for root privileges
    if ! check_root; then
        return 1
    fi
    
    echo -e "${GREEN}Starting disk stress test for ${duration} seconds${NC}"
    
    # Get the first non-root disk
    local test_disk=$(lsblk -o NAME,TYPE,MOUNTPOINT | grep -v "sda" | grep "disk" | head -n1 | awk '{print $1}')
    
    if [ -z "$test_disk" ]; then
        echo -e "${RED}No suitable disk found for testing${NC}"
        return 1
    fi
    
    echo "Testing disk: $test_disk"
    
    # Run SMART test
    smartctl -t short /dev/$test_disk
    
    # Run stress-ng disk test
    stress-ng --hdd 1 --timeout $duration --metrics
}

# Keyboard Test
run_keyboard_test() {
    echo -e "${GREEN}Starting keyboard test${NC}"
    echo "Press each key on your keyboard. Press 'q' to quit."
    echo "The test will automatically end after $KEYBOARD_TEST_TIME seconds."
    
    # Create a temporary file for key logging
    local temp_file=$(mktemp)
    
    # Start key logging in background
    (
        while true; do
            read -n1 key
            if [ "$key" = "q" ]; then
                break
            fi
            echo "$key" >> "$temp_file"
        done
    ) &
    
    # Wait for specified time
    sleep $KEYBOARD_TEST_TIME
    
    # Kill background process
    kill %1 2>/dev/null
    
    # Show results
    echo -e "\n${GREEN}Keyboard test complete${NC}"
    echo "Keys pressed: $(sort "$temp_file" | uniq | tr -d '\n')"
    
    # Cleanup
    rm "$temp_file"
}

# Main menu
show_menu() {
    clear
    echo -e "${GREEN}=== Hardware Testing Suite ===${NC}"
    echo
    echo "1. Show System Information"
    echo "2. Run CPU Stress Test"
    echo "3. Run Memory Test (requires root)"
    echo "4. Run Disk Test (requires root)"
    echo "5. Run Keyboard Test"
    echo "6. Run All Tests (requires root)"
    echo "7. Exit"
    echo
    echo -n "Select an option (1-7): "
}

# Check for required commands at startup
if ! check_requirements; then
    echo -e "${RED}Please install the missing commands and try again${NC}"
    exit 1
fi

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            get_system_info
            ;;
        2)
            read -p "Enter test duration in seconds (default: $DEFAULT_CPU_TEST_TIME): " duration
            duration=${duration:-$DEFAULT_CPU_TEST_TIME}
            run_cpu_test $duration
            ;;
        3)
            read -p "Enter test duration in seconds (default: $DEFAULT_MEM_TEST_TIME): " duration
            duration=${duration:-$DEFAULT_MEM_TEST_TIME}
            run_memory_test $duration
            ;;
        4)
            read -p "Enter test duration in seconds (default: $DEFAULT_DISK_TEST_TIME): " duration
            duration=${duration:-$DEFAULT_DISK_TEST_TIME}
            run_disk_test $duration
            ;;
        5)
            run_keyboard_test
            ;;
        6)
            if ! check_root; then
                echo -e "${RED}Cannot run all tests without root privileges${NC}"
                echo -e "${YELLOW}Please run this script with sudo${NC}"
            else
                echo -e "${GREEN}Running all tests...${NC}"
                get_system_info
                run_cpu_test $DEFAULT_CPU_TEST_TIME
                run_memory_test $DEFAULT_MEM_TEST_TIME
                run_disk_test $DEFAULT_DISK_TEST_TIME
                run_keyboard_test
            fi
            ;;
        7)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done 
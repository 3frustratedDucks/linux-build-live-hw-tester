# Live Hardware Tester

A comprehensive hardware testing suite designed for live USB environments. This tool helps diagnose and stress test various hardware components of laptops and desktops.

## Features

- System Information Display
  - CPU details
  - Memory information
  - Disk information
  - Battery status and health
  - Network interfaces
  - Temperature readings

- Hardware Tests
  - CPU stress testing
  - Memory testing
  - Disk testing (including SMART tests)
  - Keyboard testing
  - Configurable test durations

## Requirements

- Ubuntu-based live USB
- Required packages:
  - stress-ng
  - memtester
  - smartctl
  - s-tui (optional, for temperature monitoring)

## Installation

1. Download the installer:
```bash
curl -L https://github.com/username/live-hw-tester/raw/main/install-hw-test.sh -o install-hw-test.sh
```

2. Make it executable:
```bash
chmod +x install-hw-test.sh
```

3. Run the installer:
```bash
./install-hw-test.sh
```

## Usage

After installation, you can run the hardware tester by:
1. Double-clicking the "Hardware Test" icon on your desktop
2. Running `hw-test.sh` from the terminal

## Test Durations

Default test durations:
- CPU Test: 5 minutes
- Memory Test: 5 minutes
- Disk Test: 10 minutes
- Keyboard Test: 1 minute

These durations can be customized during test execution.

## License

MIT License 
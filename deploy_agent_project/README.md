# Attendance Tracker Deployment Agent

## Description
This Bash script automates the setup and deployment of an attendance tracker project.

## Requirements
- Bash
- Python 3
- zip utility

## How to Run
1. Open the terminal in the project directory.
2. Run the command: ./deploy_agent.sh
3. Follow the prompts to configure and run the attendance tracker.

## Error Handling and Archiving
The script uses a signal trap to handle Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP).
When deployment is interrupted, it creates a ZIP archive of the incomplete project directory and removes that directory.

## Templates
The templates directory contains the Python attendance checker, assets CSV file, and configuration JSON file.

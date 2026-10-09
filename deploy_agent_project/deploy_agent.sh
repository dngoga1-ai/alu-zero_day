#!/bin/bash
PROJECT_DIR="/root/alu_zero_day/deploy_agent_project"
TEMPLATE_DIR="$PROJECT_DIR/templates"
if ! command -v python3 >/dev/null 2>&1; then
echo "Error: python3 is not installed."
exit 1
fi
python3 --version
if ! command -v zip >/dev/null 2>&1; then

echo "Error: Zip is not installed."
exit 1

fi

read -r -p "Enter a project name: " project_name

project_path="$PROJECT_DIR/attendance_tracker_$project_name"

handle_interrupt() {
    echo "Deployment interrupted. Creating an archive..."

    if [[ -d "$project_path" ]]; then
        zip -r "$PROJECT_DIR/attendance_tracker_${project_name}_archive.zip" "$project_path"
        rm -rf "$project_path"
    fi

    echo "Incomplete deployment archived and cleaned up."
    exit 1
}
trap handle_interrupt SIGINT SIGTSTP


if [[ -z "$project_name" ]]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

if [[ -d "$project_path" ]]; then
    read -r -p "Project already exists. Overwrite it? (y/n): " answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    rm -rf "$project_path"
fi

mkdir -p "$project_path/Helpers"
mkdir -p "$project_path/reports"
mkdir -p "$project_path/archives/attendance"
mkdir -p "$project_path/archives/absent"

echo "Project folders created successfully."

cp "$TEMPLATE_DIR/attendance_checker.py" "$project_path/"
cp "$TEMPLATE_DIR/config.json" "$project_path/Helpers/"

read -r -p "How many sample students do you want (1-9)? " sample_count

if ! [[ "$sample_count" =~ ^[1-9]$ ]]; then
    echo "Error: Enter a number from 1 to 9."
    exit 1
fi

head -n "$((sample_count + 1))" "$TEMPLATE_DIR/assets.csv" > "$project_path/Helpers/assets.csv"

chmod +x "$project_path/attendance_checker.py"
chmod 600 "$project_path/Helpers/config.json"

echo "File permissions set successfully."

read -r -p "Do you want to update the thresholds? (y/n): " update_thresholds

if [[ "$update_thresholds" == "y" || "$update_thresholds" == "Y" ]]; then
    read -r -p "Enter warning threshold (0-100): " warning
    read -r -p "Enter failure threshold (0-100): " failure

    if ! [[ "$warning" =~ ^[0-9]+$ && "$failure" =~ ^[0-9]+$ ]] ||
       (( warning > 100 || failure > 100 )); then
        echo "Error: Thresholds must be whole numbers from 0 to 100."
        exit 1
    fi

    sed -i "s/\"warning\": [0-9]*/\"warning\": $warning/" "$project_path/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $failure/" "$project_path/Helpers/config.json"
fi

echo "Verifying the deployed application..."
(
    cd "$project_path" || exit 1
    python3 attendance_checker.py
)

read -r -p "Do you want to run the application again? (y/n): " run_again

if [[ "$run_again" == "y" || "$run_again" == "Y" ]]; then
    (
        cd "$project_path" || exit 1
        python3 attendance_checker.py
    )
fi

timestamp=$(date +"%Y%m%d_%H%M%S")

if [[ -f "$project_path/reports/attendance.log" ]]; then
    cp "$project_path/reports/attendance.log" \
       "$project_path/archives/attendance/attendance_$timestamp.log"
    echo "Attendance log archived."
else
    echo "No attendance.log found to archive."
fi

if [[ -f "$project_path/reports/absent.log" ]]; then
    cp "$project_path/reports/absent.log" \
       "$project_path/archives/absent/absent_$timestamp.log"
    echo "Absent log archived."
else
    echo "No absent.log found to archive."
fi


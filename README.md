# Bash Data Processing & Automation Toolkit

A modular, robust, and safe Bash scripting toolkit designed to automate common text processing, data analysis, and file management tasks in Linux environments.

---

## 📋 Table of Contents
- [Project Overview](#-project-overview)
- [Features](#-features)
- [Directory Structure](#-directory-structure)
- [Prerequisites & Dependencies](#-prerequisites--dependencies)
- [Installation & Setup](#-installation--setup)
- [Usage Guide](#-usage-guide)
- [Function Documentation](#-function-documentation)
- [Logging & Error Handling](#-logging--error-handling)
- [Test Cases & Validation](#-test-cases--validation)

---

## 🎯 Project Overview
The **Bash Data Processing & Automation Toolkit** unifies multiple Linux command-line utilities into a single, interactive CLI application. It emphasizes production-grade scripting practices including strict error handling (`set -euo pipefail`), signal catching (`trap`), color-coded timestamped logging, input validation, and defensive file checks.

---

## ✨ Features
- **Line Counting**: Fast line tallying using stream redirection.
- **CSV Column Extraction**: Flexible column slicing with custom delimiters.
- **Regex Filtering**: Advanced text filtering powered by Extended Regular Expressions (`grep -E`).
- **Numerical Statistics**: Calculates Count, Sum, Average, Min, and Max on numeric dataset columns using `awk`.
- **File Merging**: Safe, ordered merging of multiple files with newline padding.
- **Deduplication**: Sorting and unique line extraction with duplicate count reporting.
- **System Safeguards**: Automatic directory creation, dependency checking, and graceful signal cleanup (`Ctrl+C`).

---

## 📁 Directory Structure
```text
bash-data-processing/
│
├── project_bash_script.sh    # Main interactive Bash script
├── README.md                 # Project documentation
│
├── data/                     # Input datasets (CSV, TXT, logs)
│   ├── data.csv
│   ├── data.txt
│   └── sample.txt
│
├── output/                   # Generated output files
│   ├── extracted_cols.txt
│   ├── filtered.txt
│   ├── stats.txt
│   ├── merged.txt
│   └── deduplicated.txt
│
└── logs/                     # Application execution logs
    └── project.log

⚙️ Prerequisites & Dependencies
The toolkit relies on standard Unix/Linux POSIX commands:

    bash (v4.0+)
    awk (Data analysis and calculations)
    sed (Stream editing)
    grep (Pattern matching)
    sort & uniq (Data sorting and deduplication)
    wc & cut (Word/line counting and column extraction)

🚀 Installation & Setup

    Clone or Copy the Repository:

git clone [suspicious link removed]
cd bash-data-processing

    Grant Execution Permissions:

chmod +x project_bash_script.sh

    Run the Script:

./project_bash_script.sh

🛠️ Function Documentation
Function Name
	
Description
	
Example / Usage
init_directories()
	
Creates data/, output/, and logs/ directories if missing.
	
Auto-executed on start
check_dependencies()
	
Verifies availability of awk, sed, grep, sort, wc.
	
Auto-executed on start
validate_file()
	
Checks existence, permissions, file type, and non-empty size.
	
validate_file "data/data.csv"
count_lines()
	
Counts lines in a specified file.
	
Option 1 in Menu
extract_columns()
	
Extracts CSV columns by index (e.g., 1,3).
	
Option 2 in Menu
filter_data()
	
Searches text matching a Regex pattern.
	
Option 3 in Menu
calculate_stats()
	
Computes Min, Max, Avg, Sum on numeric CSV columns.
	
Option 4 in Menu
merge_files()
	
Combines multiple text files into output/merged.txt.
	
Option 5 in Menu
deduplicate()
	
Cleans repeated lines and reports count removed.
	
Option 6 in Menu
📝 Logging & Error Handling

    Terminal Colors:
        [INFO] (Blue): General operational messages.
        [SUCCESS] (Green): Successful completion of tasks.
        [WARNING] (Yellow): Non-fatal alerts (e.g., empty search matches).
        [ERROR] (Red): Validation errors and execution failures.
    Log Archiving: All events are recorded in logs/project.log with ISO timestamps (YYYY-MM-DD HH:MM:SS).
    Signal Handling: trap cleanup SIGINT SIGTERM catches Ctrl+C to prevent corrupted outputs and guarantee safe termination.

🧪 Test Cases & Validation
✅ Valid Scenarios Tested

    Directory Setup: Initializing directories creates data/, output/, and logs/ cleanly

.
Column Slicing: Slicing columns 1,3 from data/data.csv writes correct headers and values to output/extracted_cols.txt
.
Regex Search: Filtering ERROR pattern correctly extracts failing lines and ignores valid logs
.
Deduplication: Processing a file with 10 lines (3 duplicates) successfully yields 7 unique lines and logs 3 removals

    .

❌ Invalid & Edge Scenarios Handled

    Missing File Path: Passing a non-existent path triggers [ERROR] File does not exist and aborts safely

.
Directory Input: Providing a folder path to validate_file triggers [ERROR] Target is a directory
.
Empty Output: Searching for a non-matching string logs [WARNING] No matching records found without throwing a execution panic
.
User Interruption: Pressing Ctrl+C mid-execution gracefully catches SIGINT, logs the event, and exits with code 0

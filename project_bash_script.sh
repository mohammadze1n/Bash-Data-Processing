#!/bin/bash

#============================================
# 1. safety settings 
set -Eeuo pipefail

#============================================
#  2. terminal colors
blue='\033[0;34m'
green='\033[0;32m'
yellow='\033[1;33m'
red='\033[0;31m'
nc='\033[0m' #no color 

#=============================================
#  3. log file path
log_file="logs/project.log"

#==============================================
#  4. logging function
log_message() {
 local level="${1^^}"
 local message="${2:-}"
 local timestamp
 timestamp=$(date "+%Y-%m-%d %H:%M:%S")
   # defining color according to message type
 local color="$nc"
 case "$level" in
       "INFO") color="$blue" ;;
       "SUCCESS") color="$green" ;;
       "WARNING") color="$yellow"  ;;
       "ERROR")  color="$red" ;;
        *) color="$nc"  ;;
  esac

  # printing colored message on terminal
  echo -e "${color}[${timestamp}] [${level}] ${message}${nc}"

  # saving without colors to log file
  echo "[${timestamp}] [${level}] ${message}" >> "$log_file"
}

#=====================================================================
init_directories () {
mkdir -p "logs"
log_message "Info" "Initializing project directories..."

local dirs=("data" "output" "logs")
local dir
for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_message "Info" "Created missing directory: $dir"
    fi
done    
  log_message "Success" "All required directories are ready"
}

#===========================================================
command_exists() {
    local cmd="${1:-}"
    command -v "$cmd" >/dev/null 2>&1
}

#=============================================================
check_dependencies() {
   log_message "Info" "Checking required dependencies..."
   local required_cmds=("awk" "sed" "grep" "sort" "uniq" "wc" "cut" "head" "cat" "date")
   local missing_count=0
   local cmd

   for cmd in "${required_cmds[@]}"; do
   if command_exists "$cmd"; then
        log_message "Success" "Command '$cmd' is installed."
   else
       log_message "Error"  "Required command '$cmd' is missing"
       missing_count=$((missing_count + 1))
   fi    
   done

  if [[ "$missing_count" -gt 0 ]]; then
     log_message "Error" "Dependency check failed: $missing_count tool(s) missing."
     return 1
  fi
 log_message "Success" "All required dependencies are verified"
}

#==================================================================
validate_file() {
   local file="${1:-}"

   if [[ -z "$file" ]]; then
      log_message "Error" "No file path provided"
      return 1
    fi

     if [[ ! -e "$file" ]]; then
     log_message "Error" "File does not exist: [$file]"
     return 1
     fi

     if [[ ! -f "$file" ]]; then
     log_message "Error" "Target [$file] is a directory, not a regular file"
     return 1
     fi

     if [[ ! -r "$file" ]]; then
     log_message "Error" "Read permission denied for file: [$file]"
     return 1
     fi

    if [[ ! -s "$file" ]]; then
    log_message "Warning" "File is empty: [$file]"
    return 1
    fi

    return 0
}

#===================================================================
count_lines() {
   local file="${1:-}"

    if ! validate_file "$file"; then 
    return 1
    fi

    log_message "Info" "Counting Lines in $file..."
    local line_count
    line_count=$(wc -l < "$file")

    log_message "Success" "Number of lines: $line_count"

}

#====================================================================
extract_columns() {
  local file="${1:-}"
  local cols="${2:-}"

  if ! validate_file "$file"; then
     return 1
  fi

  if [[ -z "$cols" ]]; then
  log_message "Error" "No column numbers provided Ex: extract_columns 'data/data.csv' '1,3'"
      return 1
  fi

  local total_cols
  local col
  local -a col_list
  total_cols=$(head -n 1 "$file" | awk -F',' '{print NF}')
  IFS=',' read -ra col_list <<< "$cols"

  for col in "${col_list[@]}"; do
      if ! [[ "$col" =~ ^[0-9]+$ ]] || (( col < 1 || col > total_cols )); then
          log_message "Error" "Invalid column number: $col"
          return 1
      fi
  done

  log_message "Info" "Extracting column(s) [$cols] from $file.."
 
  local output_file="output/extracted_cols.txt"

  if cut -d',' -f"$cols"  "$file" > "$output_file"; then
    log_message "Success" "Extracted columns saved to $output_file"
    echo "-------------------------------------------------"
    head -n 5 "$output_file"
    echo "-------------------------------------------------"
  else
    log_message "Error" "Failed to extract columns. Please check your column numbers"
  return 1
  fi
}

#======================================================================
filter_data() {
   local file="${1:-}"
   local pattern="${2:-}"

   if ! validate_file "$file"; then
   return 1
   fi

   if [[ -z "$pattern" ]]; then
   log_message "Error" "No search pattern provided EX: filter_data 'data/data.txt' 'Error'"
   return 1
   fi


  log_message "Info" "Filtering data in $file with pattern '$pattern'.."

  local output_file="output/filtered.txt"
  local status=0

  grep -E "$pattern" "$file" > "$output_file" || status=$?

  if [[ "$status" -eq 0 ]]; then
  local match_count
  match_count=$(wc -l < "$output_file")
  log_message "Success" "Found $match_count matching records. saved to $output_file"
  echo "----------------------------------------------"
  head -n 5 "$output_file"
  echo "----------------------------------------------"
  elif [[ "$status" -eq 1 ]]; then
     log_message "Warning" "No matching records found for pattern '$pattern'"
  else
     log_message "Error" "Invalid regular expression: '$pattern'"
     return 1
  fi

}

#=========================================================================================
calculate_stats() {
local file="${1:-}"
local col="${2:-}"

if ! validate_file "$file"; then
 return 1
fi


if [[  -z "$col" ]]; then
 log_message "Error" "No column number provided! EX: calculate_stats 'data/numbers.csv' 2"
return 1
fi

if ! [[ "$col" =~ ^[0-9]+$ ]] || (( col < 1 )); then
 log_message "Error" "Invalid column number: $col"
 return 1
fi

log_message "Info" "Calculating numerical statistics for column $col in $file.."

local output_file="output/stats.txt"
    awk -F',' -v col="$col" '
    BEGIN {
        sum = 0;
        count = 0;
        min = 0;
        max = 0;
    }
    {
        val = $col;
        # Check if value is a valid integer or decimal number
        if (val ~ /^-?[0-9]+(\.[0-9]+)?$/) {
            val = val + 0;
            count++;
            sum += val;
            if (count == 1 || val < min) min = val;
            if (count == 1 || val > max) max = val;
        }
    }
    END {
        if (count > 0) {
            avg = sum / count;
            printf "=== Numerical Statistics ===\n";
            printf "Total Records : %d\n", count;
            printf "Sum           : %.2f\n", sum;
            printf "Average       : %.2f\n", avg;
            printf "Minimum       : %.2f\n", min;
            printf "Maximum       : %.2f\n", max;
        } else {
            print "Error: No valid numerical data found in column " col;
        }
    }
    ' "$file" > "$output_file"

    if [[ -s "$output_file" ]] && ! grep -q "Error:" "$output_file"; then
        log_message "Success" "Statistics calculated successfully. Saved to $output_file"
        echo "----------------------------------------"
        cat "$output_file"
        echo "----------------------------------------"
    else
        log_message "Error" "Failed to calculate statistics or no valid numeric data found."
        return 1
    fi
}

#=======================================================================================

# Merge Multiple Files into a Single Output File
merge_files() {
    local output_file="output/merged.txt"

    # Check if at least two files were provided as arguments
    if [[ "$#" -lt 2 ]]; then
        log_message "Error" "At least two files are required Ex: merge_files 'data/file1.txt' 'data/file2.txt'"
        return 1
    fi

    local file

    # Validate all input files before merging anything
    for file in "$@"; do
        if ! validate_file "$file"; then
            log_message "Error" "Merge stopped. Invalid file: [$file]"
            return 1
        fi
    done

    log_message "Info" "Merging $# files into $output_file..."

    # Clear or initialize the destination output file
    > "$output_file"

    # Loop through all input file paths passed to the function ($@)
    for file in "$@"; do
        log_message "Info" "Appending $file to $output_file..."
        sed -e '$a\' "$file" >> "$output_file"
    done

    local total_lines
    total_lines=$(wc -l < "$output_file")
    log_message "Success" "Successfully merged $# file(s) ($total_lines lines) into $output_file"
    echo "----------------------------------------"
    head -n 5 "$output_file"
    echo "----------------------------------------"
}

#========================================================================================
deduplicate() {
    local file="${1:-}"

    # Validate file safety before processing
    if ! validate_file "$file"; then
        return 1
    fi

    log_message "Info" "Removing duplicate lines from $file..."

    local output_file="output/unique.txt"
    local initial_count
    local unique_count
    local removed_count

    # Count initial lines
    initial_count=$(grep -c '' "$file")

    # Remove duplicates while keeping the original order
    if awk '!seen[$0]++' "$file" > "$output_file"; then
        unique_count=$(grep -c '' "$output_file")
        removed_count=$((initial_count - unique_count))

        log_message "Info" "Original lines: $initial_count"
        log_message "Success" "Unique lines: $unique_count"
        log_message "Success" "Duplicates removed: $removed_count. Saved to $output_file"
        echo "----------------------------------------"
        head -n 5 "$output_file"
        echo "----------------------------------------"
    else
        log_message "Error" "Failed to remove duplicates from $file."
        return 1
    fi
}

#===================================================================================================

#Signal Handler / Cleanup Function
cleanup() {
    echo ""
    log_message "Error" "Script interrupted by user."
    exit 130
}

on_error() {
    log_message "Error" "An unexpected error occurred (line $1)."
}

# Register signal traps for graceful exit (ctrl+c or SIGTERM)
trap cleanup SIGINT SIGTERM
trap 'on_error $LINENO' ERR

# Display Main Menu Options
show_menu() {
    echo ""
    echo "=================================================="
    echo "   Bash Data Processing & Automation Toolkit"
    echo "=================================================="
    echo " 1. Count lines in a file"
    echo " 2. Extract specific columns (CSV)"
    echo " 3. Filter data using Regular Expressions (Regex)"
    echo " 4. Calculate numerical statistics (Min, Max, Avg)"
    echo " 5. Merge multiple files"
    echo " 6. Remove duplicate lines"
    echo " 7. Check system dependencies"
    echo " 8. Initialize/Reset project directories"
    echo " 9. Exit toolkit"
    echo "=================================================="
}

# Main Event Loop
main_menu() {
    local choice
    local input_file
    local cols
    local pattern
    local col_num
    local -a files_array

    while true; do
        show_menu
        read -r -p "Enter your choice [1-9]: " choice

        case "$choice" in
            1)
                read -r -p "Enter file path: " input_file
                count_lines "$input_file" || true
                ;;
            2)
                read -r -p "Enter CSV file path: " input_file
                read -r -p "Enter column numbers (e.g., 1,3): " cols
                extract_columns "$input_file" "$cols" || true
                ;;
            3)
                read -r -p "Enter file path: " input_file
                read -r -p "Enter search pattern/Regex: " pattern
                filter_data "$input_file" "$pattern" || true
                ;;
            4)
                read -r -p "Enter CSV file path: " input_file
                read -r -p "Enter column number to calculate: " col_num
                calculate_stats "$input_file" "$col_num" || true
                ;;
            5)
                read -r -p "Enter file paths separated by space: " -a files_array
                merge_files "${files_array[@]}" || true
                ;;
            6)
                read -r -p "Enter file path: " input_file
                deduplicate "$input_file" || true
                ;;
            7)
                check_dependencies || true
                ;;
            8)
                init_directories || true
                ;;
            9)
                log_message "Info" "Exiting Toolkit. Thank you!"
                exit 0
                ;;
            ''|*[!0-9]*)
                log_message "Error" "Invalid option. Please enter a number between 1 and 9."
                ;;
            *)
                log_message "Error" "Invalid choice."
                ;;
        esac

        echo ""
        read -r -p "Press [Enter] key to return to the main menu..."
    done
}

init_directories
check_dependencies || exit 1
main_menu

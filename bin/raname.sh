#!/usr/bin/env bash

set -e  # Exit on error

# Default settings
ignore_case=false
exclude_dirs=()  # Start with empty array
dry_run=false
copy_mode=false
log_dir="${HOME}/.raname_logs"
log_file="${log_dir}/raname.log"

# Create log directory if it doesn't exist
mkdir -p "$log_dir"

# Function to log changes with timestamp and type
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$type] $message" | tee -a "$log_file"
}

# Usage guide
usage() {
  echo "Usage: raname [OPTIONS] <old_text> <new_text> [directory]"
  echo ""
  echo "Options:"
  echo "  -i, --ignore-case       Case-insensitive matching"
  echo "  -e, --exclude <dirs>    Comma-separated list of directories to exclude"
  echo "  --dry-run               Show what would be changed without modifying anything"
  echo "  --copy                  Create a renamed copy instead of renaming in-place"
  echo "  -h, --help              Show this help message"
  exit 1
}

# Parse CLI options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ignore-case) ignore_case=true; shift ;;
    -e|--exclude) exclude_dirs+=(${2//,/ }); shift 2 ;;  # Add to exclude list
    --dry-run) dry_run=true; shift ;;
    --copy) copy_mode=true; shift ;;
    -h|--help) usage ;;
    --) shift; break ;;  # End of options
    -*) echo "Unknown option: $1"; usage ;;
    *) break ;;  # Positional arguments
  esac
done

# Require at least old_text and new_text
if [[ $# -lt 2 ]]; then
  usage
fi

old_text="$1"
new_text="$2"
target_dir="${3:-.}"

# Get absolute path of target directory
target_dir=$(realpath "$target_dir")
parent_dir=$(dirname "$target_dir")
original_parent_dir="$parent_dir"  # Store original parent directory for copy mode
dir_name=$(basename "$target_dir")

# Convert case for ignore-case mode
if $ignore_case; then
  lc_old_text="${old_text,,}"
  lc_new_text="${new_text,,}"
fi

# Exclude directories in find
exclude_expr=()
for ex in "${exclude_dirs[@]}"; do
  exclude_expr+=( -path "$target_dir/$ex" -prune -o )
done

# **Use a temporary directory if in copy mode**
if $copy_mode; then
    temp_dir="$(mktemp -d)"
    temp_target="$temp_dir/$(basename "$target_dir")"

    if $dry_run; then
        echo "Would copy root directory: $target_dir -> $temp_target"
    else
        log "COPY" "Copying root directory to temporary location: $temp_target"
        cp -r "$target_dir" "$temp_dir/"
        target_dir="$temp_target"
        parent_dir="$temp_dir"  # Update parent_dir for temporary location
    fi
fi

# 1. Replace Text in File Contents First
find "$target_dir" "${exclude_expr[@]}" -type f ! -name ".DS_Store" -print0 | while IFS= read -r -d '' file; do
    if $dry_run; then
        echo "Would replace text in: $file"
    else
        if grep -q "$old_text" "$file"; then
            if $ignore_case; then
                perl -pi -e "s/\Q$old_text\E/$new_text/gi" "$file"
            else
                perl -pi -e "s/\Q$old_text\E/$new_text/g" "$file"
            fi
            log "REPLACE" "Modified content in: $file"
        fi
    fi
done

# 2. Rename Files and Directories After Content Change
# First, rename directories from deepest to shallowest (excluding the target directory itself)
find "$target_dir" -depth "${exclude_expr[@]}" ! -path "$target_dir" -type d -name "*$old_text*" -print0 | while IFS= read -r -d '' item; do
    new_item="${item//$old_text/$new_text}"
    [[ "$item" == "$new_item" ]] && continue

    if $dry_run; then
        echo "Would rename: $item -> $new_item"
    else
        # Create parent directory if it doesn't exist (needed for copy mode)
        mkdir -p "$(dirname "$new_item")"
        log "RENAME" "Renaming: $item -> $new_item"
        mv "$item" "$new_item"
    fi
done

# Then rename files
find "$target_dir" -depth "${exclude_expr[@]}" ! -path "$target_dir" -type f -name "*$old_text*" -print0 | while IFS= read -r -d '' item; do
    new_item="${item//$old_text/$new_text}"
    [[ "$item" == "$new_item" ]] && continue

    if $dry_run; then
        echo "Would rename: $item -> $new_item"
    else
        # Create parent directory if it doesn't exist (needed for copy mode)
        mkdir -p "$(dirname "$new_item")"
        log "RENAME" "Renaming: $item -> $new_item"
        mv "$item" "$new_item"
    fi
done

# Finally, rename the target directory itself if needed
if [[ "$dir_name" == *"$old_text"* ]]; then
    new_dir_name="${dir_name//$old_text/$new_text}"
    new_target_dir="$parent_dir/$new_dir_name"
    
    if $dry_run; then
        echo "Would rename directory: $target_dir -> $new_target_dir"
    else
        # Create parent directory if it doesn't exist (needed for copy mode)
        mkdir -p "$(dirname "$new_target_dir")"
        log "RENAME" "Renaming directory: $target_dir -> $new_target_dir"
        mv "$target_dir" "$new_target_dir"
        target_dir="$new_target_dir"  # Update target_dir for copy mode
    fi
fi

# Cleanup empty directories
if ! $dry_run; then
    find "$target_dir" -type d -empty -delete 2>/dev/null || true
fi

# **Move the processed temporary directory to final destination**
if $copy_mode && ! $dry_run; then
    final_name=$(basename "$target_dir")
    log "COPY" "Moving processed directory to final location: $target_dir -> $original_parent_dir/$final_name"
    cp -r "$target_dir" "$original_parent_dir/"
    rm -rf "$temp_dir"  # Clean up temp directory
fi

if $dry_run; then
    echo "Dry run complete. No changes made."
else
    log "INFO" "Rename operation completed."
fi

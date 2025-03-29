#!/usr/bin/env bash

set -e  # Exit on error

# Default settings
strict_mode=false  # Default is loose mode
exclude_dirs=(".git")  # Always exclude .git
dry_run=false
copy_mode=false
debug=false
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

# Function to generate case variations
generate_case_variations() {
    local old_text="$1"
    local new_text="$2"
    local variations=()
    
    if $strict_mode; then
        # If strict mode, only use the original pair
        variations+=("$old_text:$new_text")
    else
        # Generate all variations in loose mode
        # Original case
        variations+=("$old_text:$new_text")
        
        # Title Case (first letter capitalized)
        variations+=("$(echo "$old_text" | perl -pe 's/^./uc($&)/e'):$(echo "$new_text" | perl -pe 's/^./uc($&)/e')")
        
        # UPPERCASE
        variations+=("$(echo "$old_text" | perl -pe '$_ = uc'):$(echo "$new_text" | perl -pe '$_ = uc')")
        
        # lowercase
        variations+=("$(echo "$old_text" | perl -pe '$_ = lc'):$(echo "$new_text" | perl -pe '$_ = lc')")
    fi
    
    # Remove duplicates while preserving order
    local unique_variations=()
    for var in "${variations[@]}"; do
        if [[ ! " ${unique_variations[@]} " =~ " ${var} " ]]; then
            unique_variations+=("$var")
        fi
    done
    
    echo "${unique_variations[@]}"
}

# Usage guide
usage() {
  echo "Usage: raname [OPTIONS] <pairs> [directory]"
  echo ""
  echo "Options:"
  echo "  --strict               Case-sensitive matching (no case variations)"
  echo "  -e, --exclude <dirs>  Comma-separated list of directories to exclude"
  echo "  --dry-run             Show what would be changed without modifying anything"
  echo "  --copy                Create a renamed copy instead of renaming in-place"
  echo "  --debug               Enable debug mode to keep temporary files"
  echo "  -h, --help            Show this help message"
  echo ""
  echo "Pairs format: old_text:new_text,old_dir:new_dir"
  echo "Example: foo:bar,dir1:dir2"
  exit 1
}

# Parse CLI options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict_mode=true; shift ;;
    -e|--exclude) exclude_dirs+=(${2//,/ }); shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    --copy) copy_mode=true; shift ;;
    --debug) debug=true; shift ;;
    -h|--help) usage ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1"; usage ;;
    *) break ;;
  esac
done

# Require at least one pair
if [[ $# -lt 1 ]]; then
  usage
fi

# Parse input pairs
pairs="$1"
target_dir="${2:-.}"

# Get absolute path of target directory
target_dir=$(realpath "$target_dir")
parent_dir=$(dirname "$target_dir")
dir_name=$(basename "$target_dir")

echo "Target directory: $target_dir"
echo "Parent directory: $parent_dir"
echo "Directory name: $dir_name"

# Create temporary directories for operations
temp_dir="$(mktemp -d)"
temp_target="$temp_dir/$(basename "$target_dir")"
echo "Would create temporary directory: $temp_target"

# Create separate temporary directory for structure files
structure_dir="$(mktemp -d)"
echo "Would create structure temporary directory: $structure_dir"

# Copy target directory to temporary location
echo "Would copy target directory to temporary location"
cp -r "$target_dir" "$temp_dir/"

# Generate original file structure list
echo "Would generate original file structure list in: $structure_dir/original_structure.txt"
# First get all directories
find "$temp_target" -type d -print0 | while IFS= read -r -d '' dir; do
    echo "$dir" >> "$structure_dir/original_structure.txt"
done
# Then get all files
find "$temp_target" -type f ! -name ".DS_Store" -print0 | while IFS= read -r -d '' file; do
    echo "$file" >> "$structure_dir/original_structure.txt"
done

# Process each pair
IFS=',' read -ra PAIRS <<< "$pairs"
echo "Processing in directory: $target_dir"
echo "----------------------------------------"

# Start with original structure
cp "$structure_dir/original_structure.txt" "$structure_dir/final_structure.txt"

# Preprocess all variations
declare -a all_variations
for pair in "${PAIRS[@]}"; do
    IFS=':' read -r old_text new_text <<< "$pair"
    variations=($(generate_case_variations "$old_text" "$new_text"))
    printf '%s\n' "${variations[@]}"
    all_variations+=("${variations[@]}")
done

# Save all variations to a file
echo "Saving all variations to: $structure_dir/all_variations.txt"
printf '%s\n' "${all_variations[@]}" > "$structure_dir/all_variations.txt"
echo "----------------------------------------"
cat "$structure_dir/all_variations.txt"
echo "----------------------------------------"

# Check file contents for matches
echo "Checking file contents for matches..."
echo "Saving content changes to: $structure_dir/file_content_changes.txt"
> "$structure_dir/file_content_changes.txt"  # Create empty file

# Read original structure and check each file
while IFS= read -r file_path; do
    if [ -f "$file_path" ]; then
        # Convert path to be relative to target directory
        rel_path="${file_path#$temp_dir/}"
        matched_pairs=()

        for variation in "${all_variations[@]}"; do
            IFS=':' read -r var_old var_new <<< "$variation"
            # Use grep to find matches and count occurrences
            match_count=$(grep -c "$var_old" "$file_path" 2>/dev/null || true)
            if [ "$match_count" -gt 0 ]; then
                matched_pairs+=("$var_old:$var_new:$match_count")
            fi
        done
        
        # If any matches were found, save file path and matches in a single line
        if [ ${#matched_pairs[@]} -gt 0 ]; then
            echo "$rel_path|${matched_pairs[*]}" >> "$structure_dir/file_content_changes.txt"
        fi
    fi
done < "$structure_dir/original_structure.txt"

# Process all variations at once
for variation in "${all_variations[@]}"; do
    IFS=':' read -r var_old var_new <<< "$variation"
    perl -pi -e "s|\Q$var_old\E|$var_new|g" "$structure_dir/final_structure.txt"
done


# Get line counts
orig_count=$(wc -l < "$structure_dir/original_structure.txt")
final_count=$(wc -l < "$structure_dir/final_structure.txt")

if [ "$orig_count" != "$final_count" ]; then
    echo "Error: Line count mismatch between original and final structure files"
    echo "Original: $orig_count, Final: $final_count"
    exit 1
fi

# Create a combined file with original and final paths
paste "$structure_dir/original_structure.txt" "$structure_dir/final_structure.txt" > "$structure_dir/combined.txt"

# Create clean version without temp directory paths
sed "s|$temp_dir/||g" "$structure_dir/combined.txt" > "$structure_dir/combined_clean.txt"

root_changed=false
first_line=$(head -n 1 "$structure_dir/combined.txt")

echo "----------------------------------------"
echo "raname will perform the following operations:"

if [ -n "$first_line" ]; then
    old_root=$(echo "$first_line" | cut -f1 | xargs basename)
    new_root=$(echo "$first_line" | cut -f2 | xargs basename)
    if [ "$old_root" != "$new_root" ]; then
        root_changed=true
        echo "Root directory will be renamed from '$old_root' to '$new_root'"
    else
        echo "Root directory name '$old_root' remains unchanged"
    fi
fi
echo "File and directory changes:"

# Compare original and final structures for all paths
while IFS=$'\t' read -r old_path new_path; do
    if [ -n "$old_path" ] && [ -n "$new_path" ]; then
        # Convert paths to be relative to target directory
        rel_old_path="${old_path#$temp_dir/}"
        rel_new_path="${new_path#$temp_dir/}"
        # Only show if paths are different
        if [ "$rel_old_path" != "$rel_new_path" ]; then
            echo "     - $rel_old_path -> $rel_new_path"
        fi
    fi
done < "$structure_dir/combined.txt"

echo "----------------------------------------"

# Show file content changes
if [ -s "$structure_dir/file_content_changes.txt" ]; then
    echo "File Content Changes:"
    while IFS='|' read -r file_path patterns; do
        echo "     - $file_path"
        echo "       Replace:"
        # Split patterns into array and show each pair
        IFS=' ' read -ra pairs <<< "$patterns"
        for pair in "${pairs[@]}"; do
            IFS=':' read -r old new count <<< "$pair"
            echo "         $old -> $new ($count occurrences)"
        done
    done < "$structure_dir/file_content_changes.txt"
    echo "----------------------------------------"
fi

log "INFO" "Dry run completed."



# If not dry run, perform actual changes
if [ "$dry_run" != "true" ]; then
    echo "Performing actual changes..."
    
    # Create final directory
    final_dir="$(mktemp -d)"
    echo "Created final directory: $final_dir"
    
    # Process file content changes
    echo "Processing file content changes..."
    while IFS='|' read -r file_path patterns; do
        if [ -f "$temp_dir/$file_path" ]; then
            echo "  Processing: $file_path"
            # Create target directory if it doesn't exist
            target_dir="$final_dir/$(dirname "$file_path")"
            mkdir -p "$target_dir"
            
            # Apply all replacements
            cp "$temp_dir/$file_path" "$final_dir/$file_path"
            for pair in $patterns; do
                IFS=':' read -r old new count <<< "$pair"
                if [ "$count" -gt 0 ]; then
                    perl -pi -e "s|\Q$old\E|$new|g" "$final_dir/$file_path"
                fi
            done
        fi
    done < "$structure_dir/file_content_changes.txt"
    
    # Process file moves/renames
    echo "Processing file moves and renames..."
    
    # First handle root directory change if needed
    if [ "$root_changed" = "true" ]; then
        echo "Root directory will be renamed from '$old_root' to '$new_root'"
        # Create new root directory
        mkdir -p "$final_dir/$new_root"
    fi
    
    # Process all paths in order (directories first, then files)
    while IFS=$'\t' read -r old_path new_path; do
        if [ -n "$old_path" ] && [ -n "$new_path" ]; then
            # Convert paths to be relative to temp directory
            rel_old_path="${old_path#$temp_dir/}"
            rel_new_path="${new_path#$temp_dir/}"
            
            if [ "$rel_old_path" != "$rel_new_path" ]; then
                if [ "$root_changed" = "true" ]; then
                    # copy the children to the new root
                    echo "Root directory will be renamed from '$old_root' to '$new_root'"
                    # Create new root directory
                    mkdir -p "$final_dir/$new_root"
                    
                    # Skip the root directory itself
                    if [ "$rel_old_path" != "$old_root" ]; then
                        echo "  Copying: $rel_old_path -> $rel_new_path"
                        # Create target directory if it doesn't exist
                        target_dir="$final_dir/$(dirname "$rel_new_path")"
                        mkdir -p "$target_dir"
                        
                        # Only copy files using cat
                        if [ -f "$temp_dir/$rel_old_path" ]; then
                            cat "$temp_dir/$rel_old_path" > "$final_dir/$rel_new_path"
                        fi
                    fi
                else
                    echo "  Copying: $rel_old_path -> $rel_new_path"
                    # Create target directory if it doesn't exist
                    target_dir="$final_dir/$(dirname "$rel_new_path")"
                    mkdir -p "$target_dir"
                    
                    # Copy with overwrite
                    if [ -f "$temp_dir/$rel_old_path" ]; then
                        cp -f "$temp_dir/$rel_old_path" "$final_dir/$rel_new_path"
                    elif [ -d "$temp_dir/$rel_old_path" ]; then
                        cp -rf "$temp_dir/$rel_old_path" "$final_dir/$rel_new_path"
                    fi
                fi
            else
                echo "  Copying: $rel_old_path -> $rel_new_path"
                # Create target directory if it doesn't exist
                target_dir="$final_dir/$(dirname "$rel_new_path")"
                mkdir -p "$target_dir"
                
                # Copy with overwrite
                if [ -f "$temp_dir/$rel_old_path" ]; then
                    cp -f "$temp_dir/$rel_old_path" "$final_dir/$rel_new_path"
                elif [ -d "$temp_dir/$rel_old_path" ]; then
                    cp -rf "$temp_dir/$rel_old_path" "$final_dir/$rel_new_path"
                fi
            fi
        fi
    done < "$structure_dir/combined.txt"
    

    if [ "$root_changed" = "true" ]; then
        rm -rf "$final_dir/$old_root"
    fi


    echo "All changes completed in: $final_dir"

    # Handle copy mode when root has changed
    if [ "$copy_mode" = "true" ] && [ "$root_changed" = "true" ]; then
        echo "Copy mode: Copying final directory to parent directory..."
        
        # Check if parent directory exists and is writable
        if [ ! -d "$parent_dir" ]; then
            echo "Error: Parent directory '$parent_dir' does not exist"
            exit 1
        fi
        
        if [ ! -w "$parent_dir" ]; then
            echo "Error: No write permission for parent directory '$parent_dir'"
            exit 1
        fi
        
        # Check if new root directory exists in final_dir
        if [ ! -d "$final_dir/$new_root" ]; then
            echo "Error: New root directory '$new_root' not found in final directory"
            exit 1
        fi
        
        # Check if target already exists in parent directory
        if [ -d "$parent_dir/$new_root" ]; then
            echo "Error: Directory '$new_root' already exists in parent directory '$parent_dir'"
            echo "Please remove or rename the existing directory first"
            exit 1
        fi
        
        # Attempt to copy
        if cp -r "$final_dir/$new_root" "$parent_dir/"; then
            echo "Successfully copied to: $parent_dir/$new_root"
        else
            echo "Error: Failed to copy directory to parent directory"
            exit 1
        fi
    else
        # remove dir_name in parent directory
        rm -rf "$parent_dir/$dir_name"
        # copy final_dir to parent_dir
        cp -r "$final_dir/$new_root" "$parent_dir/$dir_name"
    fi

    echo "Changes completed successfully."
    
fi

# Cleanup
if [ "$debug" != "true" ]; then
    rm -rf "$temp_dir"
    rm -rf "$structure_dir"
else
    echo "Debug mode: Structure directory is at: $structure_dir"
    echo "Debug mode: Temporary directory is at: $temp_dir"
    open "$structure_dir"
    open "$temp_dir"
fi




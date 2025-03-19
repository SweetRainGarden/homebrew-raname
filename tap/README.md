# SweetRainGarden/homebrew-rename

This is a Homebrew tap for the rename utility.

## Installation

```bash
brew tap SweetRainGarden/rename
```

## Usage

After installation, you can use the rename utility:

```bash
rename [options] old_name new_name directory
```

## Options

- `-i, --ignore-case`: Ignore case when matching
- `-e, --exclude`: Exclude directories from renaming
- `--dry-run`: Show what would be renamed without making changes
- `--copy`: Copy files instead of moving them

## Examples

```bash
# Basic rename
rename foo zoo my_directory

# Case-insensitive rename
rename -i Foo zoo my_directory

# Dry run
rename --dry-run foo zoo my_directory

# Copy mode
rename --copy foo zoo my_directory

# Exclude directories
rename -e exclude_me foo zoo my_directory
``` 
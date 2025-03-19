# SweetRainGarden/homebrew-rename

This tap provides the `rename` utility for Homebrew.

## Installation

```bash
brew tap SweetRainGarden/rename
brew install rename
```

## Usage

```bash
rename [options] old_text new_text directory
```

Options:
- `-i, --ignore-case`: Case-insensitive matching
- `-e, --exclude-dir`: Exclude directories matching pattern
- `-n, --dry-run`: Show what would be renamed without making changes
- `-c, --copy`: Copy files instead of renaming them
- `-v, --version`: Show version information

## Examples

```bash
# Basic rename
rename foo bar ./test_dir

# Case-insensitive rename
rename -i Foo bar ./test_dir

# Dry run
rename --dry-run foo bar ./test_dir

# Copy mode
rename --copy foo bar ./test_dir

# Exclude directories
rename -e exclude_me foo bar ./test_dir
```

## License

MIT License 
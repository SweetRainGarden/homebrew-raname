# rename

A powerful command-line utility for renaming files and directories while also updating their contents.

## Features

- Rename files and directories recursively
- Update file contents to match the new names
- Case-sensitive and case-insensitive matching
- Dry run mode to preview changes
- Copy mode to create renamed copies instead of moving
- Directory exclusion support

## Installation

### Using Homebrew

```bash
# Add the tap
brew tap SweetRainGarden/rename

# Install the formula
brew install rename
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/SweetRainGarden/homebrew-rename.git
cd homebrew-rename

# Make the script executable
chmod +x bin/rename

# Optional: Add to your PATH
ln -s "$(pwd)/bin/rename" /usr/local/bin/rename
```

## Usage

```bash
rename [options] old_name new_name directory
```

### Options

- `-i, --ignore-case`: Perform case-insensitive matching
- `-e, --exclude <dir>`: Exclude directory from renaming
- `--dry-run`: Show what would be renamed without making changes
- `--copy`: Create renamed copies instead of moving files

### Examples

```bash
# Basic rename
rename foo bar ./my_project

# Case-insensitive rename
rename -i Foo bar ./my_project

# Preview changes without applying them
rename --dry-run foo bar ./my_project

# Create renamed copies instead of moving
rename --copy foo bar ./my_project

# Exclude specific directories
rename -e node_modules -e .git foo bar ./my_project
```

## How it Works

The utility performs renaming in two phases:
1. First, it renames all files and directories except the target directory
2. Then, it renames the target directory itself

This approach prevents issues with path changes during the operation.

For file contents, it:
1. Identifies files containing the old name
2. Updates the contents with the new name
3. Preserves file permissions and timestamps

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
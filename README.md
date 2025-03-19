# raname

A command-line utility to rename files and directories recursively, replacing text in both file/directory names and their contents.

## Features

- Raname files and directories recursively
- Replace text in file contents
- Case-insensitive matching
- Copy mode to create ranamed copies instead of moving
- Dry run mode to preview changes
- Exclude specific directories

## Installation

### Using Homebrew

```bash
# Add the tap
brew tap SweetRainGarden/raname

# Install the formula
brew install raname
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/SweetRainGarden/homebrew-raname.git
cd homebrew-raname

# Make the script executable
chmod +x bin/raname

# Optional: Add to your PATH
ln -s "$(pwd)/bin/raname" /usr/local/bin/raname
```

## Usage

```bash
raname [options] old_name new_name directory
```

### Options

- `-i, --ignore-case`: Case-insensitive matching
- `-e, --exclude <dirs>`: Comma-separated list of directories to exclude
- `--dry-run`: Show what would be ranamed without making changes
- `--copy`: Create ranamed copies instead of moving files
- `-h, --help`: Show help message

### Examples

```bash
# Basic raname
raname foo bar ./my_project

# Case-insensitive raname
raname -i Foo bar ./my_project

# Dry run to preview changes
raname --dry-run foo bar ./my_project

# Create ranamed copies instead of moving
raname --copy foo bar ./my_project

# Exclude directories
raname -e node_modules -e .git foo bar ./my_project
```

## How it Works

The script processes files and directories in the following order:

1. First, it ranames all files and directories except the target directory
2. Then, it ranames the target directory itself

This ensures that nested files and directories are processed correctly.

For file contents, it:
1. Identifies files containing the old name
2. Updates the contents with the new name
3. Preserves file permissions and timestamps

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
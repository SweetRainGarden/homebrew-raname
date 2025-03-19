# homebrew-raname

This is the Homebrew tap for the `raname` utility.

## Installation

```bash
brew tap SweetRainGarden/raname
brew install raname
```

## Usage

```bash
raname [options] <old_text> <new_text> <directory>
```

## Options

- `--copy`: Copy files instead of renaming them
- `--version`: Show version information
- `--help`: Show help message

## Examples

```bash
# Rename all files and directories containing "foo" to "bar"
raname foo bar ./my_directory

# Copy files instead of renaming them
raname --copy foo bar ./my_directory
```

## License

MIT License 
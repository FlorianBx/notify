# Contributing to notify

Thanks for your interest in contributing to this project! Your contributions are greatly appreciated, whether you're:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Helping with documentation

## Development Process

This project uses GitHub to host code, track issues and feature requests, as well as accept pull requests.

## Pull Requests

Pull requests are the best way to propose changes to the codebase. Here's how to contribute:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to reach out if that's a concern.

## Report bugs using GitHub's [issue tracker](https://github.com/yourusername/terminal-notifier-swift/issues)

GitHub issues are used to track public bugs. Report a bug by [opening a new issue](https://github.com/yourusername/terminal-notifier-swift/issues/new); it's that easy!

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Development Setup

### Prerequisites

- macOS 13.0 (Ventura) or later
- Swift 6.0+
- Xcode 15.0+ (for development)

### Building

```bash
# Clone the repository
git clone https://github.com/yourusername/terminal-notifier-swift.git
cd terminal-notifier-swift

# Build the project
make build

# Or use Swift directly
swift build
```

### Testing

```bash
# Run tests
make test

# Or use Swift directly
swift test
```

### Installing for Development

```bash
# Install development version locally
make dev-install
```

### Creating a Release

```bash
# Create a release build
make release
```

## Code Style

- Use Swift conventions and follow the existing code style
- Use descriptive variable and function names
- Keep functions focused and small
- Add documentation comments for public APIs

## License

By contributing, you agree that your contributions will be licensed under its MIT License.

## References

This document was adapted from the open-source contribution guidelines for [Facebook's Draft](https://github.com/facebook/draft-js/blob/a9316a723f9e918afde44dea68b5f9f39b7d9b00/CONTRIBUTING.md).
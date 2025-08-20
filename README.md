# Notify

[![Swift](https://github.com/FlorianBx/notify/actions/workflows/swift.yml/badge.svg)](https://github.com/FlorianBx/notify/actions/workflows/swift.yml)

A modern Swift CLI tool for sending macOS User Notifications from the command line. Inspired by the excellent terminal-notifier project, this Swift 6 implementation maintains compatibility with most commands while leveraging modern macOS frameworks.

## Features

- Send rich notifications with title, subtitle, and message
- Custom notification sounds
- App activation and URL opening
- Notification removal and listing
- Native Swift implementation using UserNotifications framework
- Universal binary support (Apple Silicon)

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 6.0+ (for building from source)

## Installation

### Homebrew (Recommended)

```bash
brew install notify
```

### Manual Installation

```bash
curl -fsSL https://raw.githubusercontent.com/florianbx/notify/main/install.sh --install | bash
```

### Build from Source

```bash
git clone https://github.com/florianbx/notify.git
cd notify
make install
```

## Usage

### Basic notification
```bash
notify --message "Hello World!"
```

### Rich notification
```bash
notify --title "Build Complete" --subtitle "MyApp" --message "The build finished successfully"
```

### With sound
```bash
notify --message "Task completed" --sound "Glass"
```

### Open URL on click
```bash
notify --message "Check this out!" --open "https://github.com"
```

### Activate specific app
```bash
notify --message "Ready for review" --activate "com.apple.Safari"
```

### List delivered notifications
```bash
notify list
```

### Remove all notifications
```bash
notify remove --all
```

### Remove notifications by group
```bash
notify remove --group "MyGroup"
```

> **Note:** For backward compatibility with terminal-notifier, the legacy flag syntax (`notify --list` and `notify --remove GROUP`) is also supported when using the `send` command, but the subcommand syntax shown above is preferred.

## Development

### Building
```bash
make build
```

### Testing
```bash
make test
```

### Installing development version
```bash
make dev-install
```

### Creating release
```bash
make release
```

## Architecture

This tool is packaged as a macOS app bundle (`.app`) to comply with the UserNotifications framework requirements. The CLI binary is located at:

```
notify.app/Contents/MacOS/notify
```

The Homebrew formula creates a symlink from `/usr/local/bin/notify` to the binary inside the app bundle.

## Compatibility with terminal-notifier

This tool is inspired by and compatible with most terminal-notifier commands. If you're coming from terminal-notifier, most of your existing scripts should work with minimal changes - just replace `terminal-notifier` with `notify`.

### Key differences:
- Binary name: `terminal-notifier` → `notify`
- Requires macOS 13.0+ (vs 10.10+ for terminal-notifier)
- Built with modern Swift and UserNotifications framework
- Some advanced options may have slight differences

## Credits

This project is inspired by the excellent [terminal-notifier](https://github.com/julienXX/terminal-notifier) by [Julien Blanchard](https://github.com/julienXX). Many thanks for creating such a useful tool that has served the macOS community for years!

## License

MIT License

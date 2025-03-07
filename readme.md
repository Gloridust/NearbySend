# NearbySend 📡 💫

<p align="right">
  <a href="README_CN.md">中文版</a>
</p>

> A cross-platform file transfer application inspired by AirDrop and LocalSend.

NearbySend is a modern, lightweight file transfer application that lets you share files across devices without the need for internet connection or being on the same network. Using a combination of WiFi and Bluetooth technologies, NearbySend provides a seamless AirDrop-like experience across multiple platforms.

![License](https://img.shields.io/github/license/yourusername/nearbysend)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows-blue)

## ✨ Features

- **Zero Configuration** - Just open the app and start sharing
- **Cross-Platform** - Works across Android, iOS, macOS, and Windows
- **No Internet Required** - Transfer directly between devices
- **No Network Dependency** - Works without being on the same network
- **Fast Transfer** - Uses WiFi for high-speed transfers
- **Security First** - All transfers are encrypted end-to-end
- **User-Friendly** - Clean, intuitive UI inspired by modern design principles

## 🛠️ Tech Stack

- **Flutter** - Beautiful cross-platform UI
- **Rust** - High-performance, secure core functionality
- **Flutter Rust Bridge** - Seamless integration between Flutter and Rust
- **BLE** - For device discovery
- **P2P WiFi** - For high-speed file transfers

## 🚀 Getting Started

### Prerequisites

- Flutter (stable channel)
- Rust (latest stable)
- Android Studio / Xcode (depending on target platform)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/nearbysend.git

# Navigate to the project directory
cd nearbysend

# Install Flutter dependencies
flutter pub get

# Build Rust native libraries
cd native
cargo build --release
cd ..

# Run the application
flutter run
```

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅     |
| macOS    | ✅     |
| iOS      | 🚧     |
| Windows  | 🚧     |

## 🔍 How It Works

NearbySend uses a combination of technologies to provide a seamless file sharing experience:

1. **Device Discovery** - BLE is used to discover nearby devices
2. **Connection Establishment** - Direct WiFi connection is established between devices
3. **Secure Transfer** - Files are transferred using an encrypted connection
4. **Verification** - Integrity checking ensures files are transferred correctly

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgements

- Inspired by Apple's AirDrop and LocalSend
- Built with Flutter and Rust
- Thanks to all contributors who have helped shape NearbySend

---

<p align="center">Made with ❤️ by the NearbySend Team</p>

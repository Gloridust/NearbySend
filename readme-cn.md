# NearbySend 📡 💫

<p align="right">
  <a href="README.md">English</a>
</p>

> 一个受 AirDrop 和 LocalSend 启发的跨平台文件传输应用。

NearbySend 是一款现代化、轻量级的文件传输应用，让您无需互联网连接或在同一网络下即可跨设备共享文件。通过结合 WiFi 和蓝牙技术，NearbySend 在多个平台上提供类似 AirDrop 的无缝体验。

![许可证](https://img.shields.io/github/license/Gloridust/nearbysend)
![平台](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows-blue)

## ✨ 特性

- **零配置** - 只需打开应用即可开始共享
- **跨平台** - 支持 Android、iOS、macOS 和 Windows
- **无需互联网** - 设备之间直接传输
- **无网络依赖** - 无需处于同一网络即可工作
- **快速传输** - 使用 WiFi 进行高速传输
- **安全至上** - 所有传输均端到端加密
- **用户友好** - 清晰、直观的用户界面，灵感来自现代设计原则

## 🛠️ 技术栈

- **Flutter** - 精美的跨平台 UI
- **Rust** - 高性能、安全的核心功能
- **Flutter Rust Bridge** - Flutter 和 Rust 之间的无缝集成
- **BLE** - 用于设备发现
- **P2P WiFi** - 用于高速文件传输

## 🚀 开始使用

### 前提条件

- Flutter（稳定版）
- Rust（最新稳定版）
- Android Studio / Xcode（取决于目标平台）

### 安装

```bash
# 克隆仓库
git clone https://github.com/Gloridust/nearbysend.git

# 进入项目目录
cd nearbysend

# 安装 Flutter 依赖
flutter pub get

# 构建 Rust 原生库
cd native
cargo build --release
cd ..

# 运行应用
flutter run
```

## 📱 支持的平台

| 平台     | 状态  |
|----------|--------|
| Android  | ✅     |
| macOS    | ✅     |
| iOS      | 🚧     |
| Windows  | 🚧     |

## 🔍 工作原理

NearbySend 使用多种技术组合提供无缝的文件共享体验：

1. **设备发现** - 使用 BLE 发现附近的设备
2. **建立连接** - 在设备之间建立直接的 WiFi 连接
3. **安全传输** - 使用加密连接传输文件
4. **验证** - 完整性检查确保文件正确传输

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

1. Fork 项目
2. 创建您的特性分支（`git checkout -b feature/amazing-feature`）
3. 提交您的更改（`git commit -m 'Add some amazing feature'`）
4. 推送到分支（`git push origin feature/amazing-feature`）
5. 打开一个 Pull Request

## 📜 许可证

该项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。

## 👏 致谢

- 灵感来自苹果的 AirDrop 和 LocalSend
- 使用 Flutter 和 Rust 构建
- 感谢所有帮助塑造 NearbySend 的贡献者

---

<p align="center">由 NearbySend 团队用 ❤️ 制作</p>

# NearbySend

NearbySend 是一个类似于 AirDrop 的跨平台文件传输软件，允许用户在不同设备之间快速传输文件，无需连接到同一个局域网。

## 功能特点

- **设备发现**：自动发现附近的设备，无需手动输入 IP 地址。
- **文件传输**：快速传输文件，支持各种文件类型。
- **跨平台**：支持 macOS 和 Android 平台。

## 技术架构

- **前端**：使用 Flutter 开发，支持跨平台。
- **后端**：使用 Rust 开发，提供高性能的文件传输功能。

## 安装和使用

### 前提条件

- Flutter SDK
- Rust 编译器
- Android Studio（用于 Android 开发）
- Xcode（用于 macOS 开发）

### 安装步骤

1. 克隆仓库：

```bash
git clone https://github.com/yourusername/nearbysend.git
cd nearbysend
```

2. 安装 Flutter 依赖：

```bash
cd flutter_app
flutter pub get
```

3. 编译 Rust 后端：

```bash
cd ../rust_backend
cargo build --release
```

### 使用方法

1. 启动 Rust 后端：

```bash
cd rust_backend
cargo run
```

2. 启动 Flutter 前端：

```bash
cd flutter_app
flutter run
```

3. 在 Flutter 应用中，点击刷新按钮发现附近的设备。
4. 选择一个设备，然后点击"选择并发送文件"按钮选择要发送的文件。
5. 文件将被发送到选定的设备。

## 项目结构

```
NearbySend/
├── flutter_app/          # Flutter 前端应用
│   ├── lib/              # Flutter 代码
│   ├── android/          # Android 配置
│   ├── macos/            # macOS 配置
│   ├── pubspec.yaml      # Flutter 依赖
│   └── README.md         # 项目说明
├── rust_backend/         # Rust 后端服务
│   ├── src/              # Rust 代码
│   ├── Cargo.toml        # Rust 依赖
│   └── README.md         # 项目说明
└── README.md             # 项目总说明
```

## 贡献

欢迎贡献代码和提出问题。请遵循以下步骤：

1. Fork 仓库
2. 创建分支 (`git checkout -b feature/your-feature`)
3. 提交更改 (`git commit -am 'Add your feature'`)
4. 推送分支 (`git push origin feature/your-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。 
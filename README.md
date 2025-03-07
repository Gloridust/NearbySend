# NearbySend

一个类似于AirDrop的跨平台文件传输应用，支持Windows、macOS、Android和iOS平台。

## 功能特点

- **无需同一网络**：使用蓝牙和WiFi Direct技术，无需连接到同一个局域网即可传输文件
- **快速发现设备**：自动发现附近可用的设备
- **安全传输**：支持端到端加密，保护文件传输安全
- **简单易用**：类似AirDrop的用户体验，简单直观
- **跨平台支持**：支持Windows、macOS、Android和iOS平台

## 技术架构

NearbySend采用Flutter和Rust混合开发：

- **Flutter**：提供跨平台UI和基本功能
- **Rust**：提供高性能的核心传输引擎
- **蓝牙BLE**：用于设备发现
- **WiFi Direct**：用于高速文件传输
- **QUIC协议**：提供可靠的传输层

## 项目结构

```
nearbysend/
├── lib/                      # Flutter代码
│   ├── app/                  # 应用核心
│   ├── core/                 # 核心业务逻辑
│   ├── features/             # 功能模块
│   ├── shared/               # 共享组件
│   └── ffi/                  # FFI绑定
├── rust/                     # Rust代码
│   ├── src/                  # Rust源码
│   └── bindings/             # FFI绑定定义
├── android/                  # Android平台特定代码
├── ios/                      # iOS平台特定代码
├── macos/                    # macOS平台特定代码
└── windows/                  # Windows平台特定代码
```

## 开发环境设置

### 前提条件

- Flutter SDK
- Rust工具链
- Android Studio / Xcode（用于移动平台开发）
- Visual Studio（用于Windows开发）

### 安装步骤

1. 克隆仓库：
   ```
   git clone https://github.com/yourusername/nearbysend.git
   cd nearbysend
   ```

2. 安装Flutter依赖：
   ```
   flutter pub get
   ```

3. 编译Rust库：
   ```
   cd rust
   cargo build --release
   ```

4. 运行应用：
   ```
   flutter run
   ```

## 贡献指南

欢迎贡献代码、报告问题或提出新功能建议。请遵循以下步骤：

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 许可证

本项目采用MIT许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。

## 联系方式

如有任何问题或建议，请通过以下方式联系我们：

- 电子邮件：your.email@example.com
- GitHub Issues：[https://github.com/yourusername/nearbysend/issues](https://github.com/yourusername/nearbysend/issues) 
# 智谱AI聊天功能 - 快速开始指南

## 🎯 功能完成度

✅ 使用现有网络工具类 `APIClient`
✅ 扩展 `APIClient` 支持流式请求（SSE）
✅ `ChatRepository` 通过 `APIEndpoint` 调用接口
✅ 完整的MVVM架构
✅ 流式输出逐字显示
✅ 统一的错误处理和日志记录

---

## 🔧 配置步骤（仅需1步）

在 `DreamzeroBlog/DependencyInject/ApiClientInject.swift` 中配置API Key：

```swift
var zhipuAPIKey: Factory<String> {
    self {
        // ⚠️ 替换为你的智谱AI API Key
        return "your-actual-zhipu-ai-api-key-here"

        // 或从环境变量读取
        // if let apiKey = ProcessInfo.processInfo.environment["ZHIPU_API_KEY"] {
        //     return apiKey
        // }
    }
}
```

---

## 🚀 使用方法

### 1. 在TabView中添加聊天标签

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ArticleListView()
                .tabItem { Label("文章", systemImage: "article") }

            ChatView()  // ← 添加这里
                .tabItem { Label("AI对话", systemImage: "message") }

            PhotoGridView()
                .tabItem { Label("照片", systemImage: "photo") }
        }
    }
}
```

### 2. 或直接作为主界面

```swift
@main
struct DreamzeroBlogApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()  // 直接显示聊天界面
        }
    }
}
```

---

## 📱 功能特性

### 流式输出 ✨
- AI回答逐字显示
- 流畅的打字机效果
- 自动滚动到最新消息

### 用户体验 💬
- 美观的消息气泡
- 多轮对话记忆
- 实时输入状态
- 清空聊天记录

### 技术实现 🛠️
- 使用项目现有 `APIClient`
- 扩展 `APIClient.streamRequest()` 方法
- 通过 `ChatCompletionEndpoint` 定义接口
- 完整的错误处理和日志

---

## 🔍 架构说明

### 调用链路

```
ChatView (SwiftUI界面)
    ↓ 观察
ChatViewModel (@Observable)
    ↓ 调用
ChatRepository (业务逻辑)
    ↓ 创建
ChatCompletionEndpoint (APIEndpoint协议)
    ↓ 调用
APIClient.streamRequest() (扩展的流式方法)
    ↓ 请求
智谱AI API (https://open.bigmodel.cn/api/paas/v4)
```

### 核心代码

**1. APIClient扩展** (`Utils/Networking/APIClient.swift`)
```swift
public func streamRequest(
    _ endpoint: APIEndpoint,
    customBaseURL: URL? = nil
) async throws -> AsyncThrowingStream<String, Error>
```

**2. Endpoint定义** (`Endpoints/ZhipuAIEndpoint.swift`)
```swift
public struct ChatCompletionEndpoint: APIEndpoint {
    public var path: String { "/chat/completions" }
    public var method: HTTPMethod { .post }
    public var headers: HTTPHeaders? {
        // 自动添加 Authorization: Bearer <apiKey>
    }
}
```

**3. Repository使用** (`Repositorys/ChatRepository.swift`)
```swift
func streamChat(...) async throws -> AsyncThrowingStream<String, Error> {
    let endpoint = ChatCompletionEndpoint(
        model: model,
        messages: messages,
        apiKey: apiKey
    )

    let jsonStream = try await client.streamRequest(
        endpoint,
        customBaseURL: URL(string: zhipuBaseURL)!
    )

    // 处理JSON解析...
}
```

---

## 📖 API Key获取

1. 访问 [智谱AI开放平台](https://open.bigmodel.cn/)
2. 注册/登录账号
3. 进入控制台 → API Keys
4. 创建新的API Key
5. 复制并配置到项目中

---

## 💡 使用提示

### 发送消息
```swift
let viewModel = Container.shared.chatViewModel()
viewModel.inputText = "你好，请介绍一下自己"
viewModel.sendMessage()
```

### 清空聊天
```swift
viewModel.clearChat()
```

### 切换模型
在 `ChatViewModel.swift` 中修改：
```swift
private let model: String = "glm-4.7"  // 可选：
// "glm-4-plus"   - 更强大
// "glm-4-flash"  - 更快（免费）
// "glm-4-air"    - 轻量级
```

---

## ⚠️ 注意事项

1. **API Key安全**
   - 不要提交到公开仓库
   - 建议使用环境变量
   - 生产环境使用后端代理

2. **网络要求**
   - 需要互联网连接
   - 确保能访问 open.bigmodel.cn

3. **费用控制**
   - 智谱AI按token计费
   - 建议设置用量限制
   - 可使用免费模型降低成本

---

## 🐛 故障排查

### 问题1: 编译错误
```bash
# 清理并重新编译
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 问题2: API Key未配置
检查日志输出：
```
⚠️ 智谱AI API Key未配置，请在ApiClientInject.swift中设置
```

### 问题3: 网络请求失败
- 检查网络连接
- 确认API Key正确
- 查看Xcode控制台日志

### 问题4: 流式输出不显示
- 检查 `ChatViewModel` 是否正确初始化
- 确认 `ChatView` 的 `@State` 变量
- 查看是否有错误日志

---

## 📚 相关文档

- **`CHAT_FEATURE_README.md`** - 功能详细说明
- **`REFACTOR_SUMMARY.md`** - 网络层重构说明
- **智谱AI官方文档**: https://docs.bigmodel.cn/
- **流式消息说明**: https://docs.bigmodel.cn/cn/guide/capabilities/streaming

---

## ✅ 检查清单

使用前请确认：

- [ ] 已配置智谱AI API Key
- [ ] `APIClient.swift` 已添加 `streamRequest()` 方法
- [ ] `ChatRepository` 使用 `APIClient` 而不是 `URLSession`
- [ ] 依赖注入配置正确
- [ ] 项目编译无错误

---

## 🎉 完成！

配置完成后，运行项目即可看到聊天界面。输入消息后，AI回答会逐字显示在界面上。

---

**Created by Claude** on 2025-12-27

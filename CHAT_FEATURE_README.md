# 智谱AI聊天功能使用说明

## 功能概述

已成功集成智谱AI（BigModel.cn）的聊天功能，支持**实时流式输出**，在界面上逐渐显示AI回答。

## 📁 新增文件

### 数据层
- `DTO/ChatDto.swift` - 聊天相关的数据传输对象（请求/响应DTO）
- `Models/ChatMessage.swift` - 聊天消息领域模型

### 网络层
- `Endpoints/ZhipuAIEndpoint.swift` - 智谱AI API端点定义
- `Repositorys/ChatRepository.swift` - 聊天仓库（支持SSE流式响应）

### 业务层
- `ViewModels/ChatViewModel.swift` - 聊天视图模型（管理聊天状态和消息）

### 视图层
- `Views/ChatView.swift` - 聊天界面（支持流式显示）

### 依赖注入
- `DependencyInject/ApiClientInject.swift` - 已添加智谱AI API Key配置
- `DependencyInject/RepositoryInject.swift` - 已注册ChatRepository
- `DependencyInject/ViewModelInject.swift` - 已注册ChatViewModel

## 🔧 配置步骤

### 1. 配置智谱AI API Key

在 `DreamzeroBlog/DependencyInject/ApiClientInject.swift` 中配置您的API Key：

```swift
var zhipuAPIKey: Factory<String> {
    self {
        // ⚠️ 请替换为您的智谱AI API Key
        return "your-actual-api-key-here"

        // 或者从环境变量读取（推荐）
        // if let apiKey = ProcessInfo.processInfo.environment["ZHIPU_API_KEY"] {
        //     return apiKey
        // }

        // 或者从Info.plist读取
        // if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ZhipuAPIKey") as? String {
        //     return apiKey
        // }
    }
}
```

### 2. 获取智谱AI API Key

1. 访问 [智谱AI开放平台](https://open.bigmodel.cn/)
2. 注册/登录账号
3. 进入控制台，创建API Key
4. 复制API Key到项目中

### 3. 在App中使用ChatView

在需要显示聊天界面的地方，使用以下代码：

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatView()  // 显示聊天界面
    }
}
```

或者在TabView中：

```swift
TabView {
    ChatView()
        .tabItem {
            Label("AI对话", systemImage: "message")
        }
}
```

## 🎨 功能特性

### 1. 流式输出
- ✅ 实时显示AI回答，逐字呈现
- ✅ 流式传输时显示"正在思考..."和"输入中..."指示器
- ✅ 自动滚动到最新消息

### 2. 聊天管理
- ✅ 多轮对话历史记录
- ✅ 清空聊天记录
- ✅ 用户/AI消息区分显示

### 3. UI交互
- ✅ 美观的消息气泡设计
- ✅ 自动调整文本框高度（支持多行输入）
- ✅ 发送按钮状态智能控制
- ✅ 流式传输时禁用输入防止重复提交

### 4. 错误处理
- ✅ 网络错误提示
- ✅ API Key未配置警告
- ✅ 流式传输失败自动恢复

## 📋 API说明

### 智谱AI API配置

- **Base URL**: `https://open.bigmodel.cn/api/paas/v4`
- **Endpoint**: `/chat/completions`
- **模型**: `glm-4`（默认，可修改为其他GLM模型）
- **认证方式**: `Bearer <API-Key>`
- **流式输出**: 通过 `stream: true` 参数启用

### 支持的模型

您可以在 `ChatViewModel.swift` 中修改模型：

```swift
private let model: String = "glm-4"  // 可改为：
// "glm-4-plus"   - 更强大的模型
// "glm-4-flash"  - 更快的免费模型
// "glm-4-air"    - 轻量级模型
```

## 🔍 代码架构说明

### MVVM + Repository 模式

```
ChatView (SwiftUI)
    ↓ 观察状态
ChatViewModel (@Observable)
    ↓ 调用方法
ChatRepository (业务逻辑)
    ↓ 网络请求
智谱AI API (流式SSE)
```

### 流式输出实现

使用Swift的 `AsyncThrowingStream` 处理SSE（Server-Sent Events）流：

```swift
// Repository返回流
func streamChat(...) async throws -> AsyncThrowingStream<String, Error>

// ViewModel逐块接收
for try await chunk in stream {
    // 更新UI
    messages[last].content += chunk
}
```

## 📝 示例代码

### 在App入口添加ChatView

```swift
import SwiftUI

@main
struct DreamzeroBlogApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ArticleListView()
                    .tabItem { Label("文章", systemImage: "article") }

                ChatView()  // ← 添加聊天标签
                    .tabItem { Label("AI对话", systemImage: "message") }

                PhotoGridView()
                    .tabItem { Label("照片", systemImage: "photo") }
            }
        }
    }
}
```

### 程序化发送消息

```swift
@State private var viewModel = Container.shared.chatViewModel()

// 发送消息
viewModel.inputText = "你好，请介绍一下自己"
viewModel.sendMessage()
```

## ⚠️ 注意事项

1. **API Key安全**
   - 不要将API Key提交到公开仓库
   - 建议使用环境变量或配置文件
   - 生产环境应使用后端代理API请求

2. **网络要求**
   - 需要网络连接
   - 可能需要配置App Transport Security（如果HTTP）

3. **费用控制**
   - 智谱AI按token计费
   - 建议设置用量限制
   - 可使用免费模型 `glm-4-flash` 降低成本

4. **错误处理**
   - API Key错误会返回401
   - 余额不足会返回特定错误码
   - 网络超时默认30秒

## 🚀 下一步优化建议

1. **会话管理**
   - 保存聊天历史到本地
   - 支持多个会话切换
   - 会话标题自动生成

2. **高级功能**
   - 支持图片上传（GLM-4V）
   - 代码高亮显示
   - Markdown渲染
   - 导出聊天记录

3. **用户体验**
   - 自定义AI角色设定
   - 调整temperature参数
   - 流式响应的打字机动画

## 📚 参考资源

- [智谱AI官方文档](https://docs.bigmodel.cn/)
- [流式消息说明](https://docs.bigmodel.cn/cn/guide/capabilities/streaming)
- [GLM-4 API参考](https://open.bigmodel.cn/dev/api)
- [Factory框架文档](https://github.com/hmlongco/Factory)

## 💡 使用提示

配置完成后，编译运行项目即可看到聊天界面。输入消息后，AI回答会**逐字显示**在界面上，提供流畅的对话体验。

---

**Created by Claude** on 2025-12-27

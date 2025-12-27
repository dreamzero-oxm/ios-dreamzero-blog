# 网络层重构说明 - 使用APIClient进行流式请求

## 🔄 重构概述

已成功将聊天功能从直接使用`URLSession`改为使用项目现有的`APIClient`工具类，并扩展了`APIClient`以支持流式请求（SSE）。

## 📝 修改文件清单

### 1. 网络层扩展 ⭐
**文件**: `DreamzeroBlog/Utils/Networking/APIClient.swift`

**新增方法**:
```swift
public func streamRequest(
    _ endpoint: APIEndpoint,
    customBaseURL: URL? = nil
) async throws -> AsyncThrowingStream<String, Error>
```

**功能说明**:
- ✅ 支持Server-Sent Events (SSE)流式响应
- ✅ 支持自定义baseURL（用于第三方API如智谱AI）
- ✅ 自动处理SSE格式的`data: `前缀
- ✅ 检测`[DONE]`结束标记
- ✅ 统一的错误处理（使用`APIError`）
- ✅ 完整的日志记录

**实现细节**:
```swift
// 1. 使用APIRequestConvertible将Endpoint转换为URLRequest
let convertible = APIRequestConvertible(baseURL: targetURL, endpoint: endpoint)
let urlRequest = try convertible.asURLRequest()

// 2. 使用URLSession.bytes()方法获取流式响应
let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

// 3. 逐行读取SSE数据
for try await line in bytes.lines {
    if line.hasPrefix("data: ") {
        let jsonString = String(line.dropFirst(6))
        if jsonString == "[DONE]" {
            continuation.finish()
            return
        }
        continuation.yield(jsonString)
    }
}
```

---

### 2. 智谱AI端点更新 🔧
**文件**: `DreamzeroBlog/Endpoints/ZhipuAIEndpoint.swift`

**修改内容**:
- ✅ 添加`apiKey`参数到`init`方法
- ✅ 在`headers`中自动添加`Authorization: Bearer <apiKey>` header
- ✅ 设置`requiresAuth: false`（因为使用自定义header）

**关键代码**:
```swift
public struct ChatCompletionEndpoint: APIEndpoint {
    private let apiKey: String?

    public init(
        model: String = "glm-4.7",
        messages: [ChatMessageDto],
        stream: Bool = false,
        temperature: Double? = nil,
        apiKey: String? = nil  // ← 新增
    ) {
        self.apiKey = apiKey
        // ...
    }

    public var headers: HTTPHeaders? {
        var headers = HTTPHeaders()
        headers.add(.contentType("application/json"))

        // 添加Bearer Token
        if let apiKey = apiKey {
            headers.add(.authorization(bearerToken: apiKey))
        }

        return headers
    }
}
```

---

### 3. 聊天仓库重构 📦
**文件**: `DreamzeroBlog/Repositorys/ChatRepository.swift`

**重构前**:
```swift
final class ChatRepository: ChatRepositoryType {
    private let apiKey: String
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // 直接使用URLSession，手动构建URLRequest
    func streamChat(...) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // ... 大量的手动处理代码
    }
}
```

**重构后**:
```swift
final class ChatRepository: ChatRepositoryType {
    private let client: APIClient  // ← 使用APIClient
    private let apiKey: String
    private let zhipuBaseURL = "https://open.bigmodel.cn/api/paas/v4"

    init(client: APIClient, apiKey: String) {  // ← 依赖注入
        self.client = client
        self.apiKey = apiKey
    }

    func streamChat(...) async throws -> AsyncThrowingStream<String, Error> {
        // 1. 创建Endpoint（包含API Key）
        let endpoint = ChatCompletionEndpoint(
            model: model,
            messages: messages,
            stream: true,
            temperature: temperature,
            apiKey: apiKey  // ← 传递API Key到Endpoint
        )

        // 2. 使用APIClient的流式请求方法
        let jsonStream = try await client.streamRequest(
            endpoint,
            customBaseURL: URL(string: zhipuBaseURL)!
        )

        // 3. 处理JSON解析（业务逻辑）
        return AsyncThrowingStream { continuation in
            for try await jsonString in jsonStream {
                let streamResponse = try JSONDecoder().decode(ChatStreamResponse.self, from: data)
                if let content = streamResponse.choices.first?.delta.content {
                    continuation.yield(content)
                }
            }
        }
    }
}
```

**改进点**:
- ✅ 使用APIClient而不是直接使用URLSession
- ✅ 通过APIEndpoint协议定义接口
- ✅ 统一的错误处理（APIError）
- ✅ 自动处理Authorization header
- ✅ 代码更简洁、职责更清晰

---

### 4. 依赖注入更新 💉
**文件**: `DreamzeroBlog/DependencyInject/RepositoryInject.swift`

**更新内容**:
```swift
var chatRepository: Factory<ChatRepositoryType> {
    self {
        ChatRepository(
            client: self.apiClient(),      // ← 注入APIClient
            apiKey: self.zhipuAPIKey()     // ← 注入API Key
        )
    }
}
```

---

## 🎯 架构优势

### 重构前的问题
1. ❌ 直接使用URLSession，绕过了项目的网络层
2. ❌ 重复的错误处理代码
3. ❌ 没有使用Endpoint协议
4. ❌ Authorization header手动设置
5. ❌ 难以测试和维护

### 重构后的优势
1. ✅ **统一网络层** - 所有请求都通过APIClient
2. ✅ **协议驱动** - 使用APIEndpoint定义接口
3. ✅ **依赖注入** - Repository注入APIClient，易于测试
4. ✅ **错误处理** - 统一使用APIError类型
5. ✅ **可扩展性** - APIClient.streamRequest()可用于其他流式接口
6. ✅ **代码复用** - Endpoint、错误处理、日志记录等逻辑复用
7. ✅ **一致性** - 与项目现有代码风格完全一致

---

## 🔍 API调用链路

### 完整的请求流程

```
ChatViewModel.sendMessage()
    ↓
ChatRepository.streamChat(messages, model, temperature)
    ↓
创建 ChatCompletionEndpoint (包含apiKey)
    ↓
APIClient.streamRequest(endpoint, customBaseURL: zhipuURL)
    ↓
APIRequestConvertible.asURLRequest()
    - 构建完整的URLRequest
    - 添加headers（Authorization, Content-Type）
    - 编码请求参数（JSON）
    ↓
URLSession.shared.bytes(for: urlRequest)
    ↓
逐行读取SSE响应
    - 过滤 "data: " 前缀
    - 检测 "[DONE]" 结束标记
    - yield JSON字符串
    ↓
ChatRepository解析JSON
    - 提取 delta.content
    - yield 文本内容
    ↓
ChatViewModel更新UI
    - 逐字显示AI回答
    - 自动滚动到底部
```

---

## 📊 代码对比

### 代码量减少
- **ChatRepository**: 从 ~100行 减少到 ~60行
- **去除重复代码**: URLRequest构建、错误处理等
- **复用现有逻辑**: APIEndpoint、APIError等

### 职责分离
```
ChatRepository        - 业务逻辑（JSON解析、内容提取）
ChatCompletionEndpoint - 接口定义（URL、参数、headers）
APIClient            - 网络请求（SSE处理、错误处理）
```

---

## 🚀 扩展性

### APIClient.streamRequest() 可复用于

1. **其他流式API**
   - OpenAI SSE接口
   - 其他大模型的流式输出
   - 实时数据推送

2. **使用示例**
```swift
// OpenAI流式请求
let endpoint = OpenAIEndpoint(...)
let stream = try await apiClient.streamRequest(endpoint)

// 自定义SSE接口
let endpoint = CustomSSEEndpoint(...)
let stream = try await apiClient.streamRequest(endpoint, customBaseURL: customURL)
```

---

## ✅ 测试建议

### 单元测试
```swift
// 测试Endpoint
let endpoint = ChatCompletionEndpoint(
    model: "glm-4.7",
    messages: [...],
    apiKey: "test-key"
)
XCTAssertEqual(endpoint.path, "/chat/completions")
XCTAssertNotNil(endpoint.headers?["Authorization"])

// 测试Repository（可Mock APIClient）
class MockAPIClient: APIClient {
    var mockStream: AsyncThrowingStream<String, Error> = ...
}
let repo = ChatRepository(client: mockClient, apiKey: "test")
```

### 集成测试
1. 配置真实API Key
2. 发送测试消息
3. 验证流式输出
4. 检查UI更新

---

## 📚 相关文件

| 文件 | 说明 |
|------|------|
| `Utils/Networking/APIClient.swift` | **新增** `streamRequest()` 方法 |
| `Endpoints/ZhipuAIEndpoint.swift` | **修改** 添加apiKey参数和Authorization header |
| `Repositorys/ChatRepository.swift` | **重构** 使用APIClient而不是URLSession |
| `DependencyInject/RepositoryInject.swift` | **更新** ChatRepository注入方式 |

---

## 🎉 总结

通过本次重构：

1. **完善了工具类** - APIClient现在支持流式请求（SSE）
2. **统一了架构** - 所有网络请求都通过APIClient
3. **提高了质量** - 错误处理、日志记录、代码复用
4. **增强了可维护性** - Endpoint驱动、依赖注入、职责分离
5. **保持了风格一致** - 完全符合项目现有代码规范

现在你可以使用扩展后的`APIClient.streamRequest()`方法来处理任何SSE流式接口，不仅仅是智谱AI！

---

**Refactored by Claude** on 2025-12-27

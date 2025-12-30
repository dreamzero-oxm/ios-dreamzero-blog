# DreamZero Blog API 文档

## 概述

DreamZero Blog 是一个全栈博客应用，提供完整的用户管理、文章发布、评论互动、每日照片等功能。本文档详细描述了用户管理相关的 API 接口。

### 基础信息

| 项目 | 说明 |
|------|------|
| **Base URL** | `http://127.0.0.1:9997/api/v1` |
| **认证方式** | Bearer Token (JWT) |
| **Content-Type** | `application/json` 或 `multipart/form-data` |
| **字符编码** | UTF-8 |

### 认证说明

需要认证的接口需要在请求头中携带有效的访问令牌：

```
Authorization: Bearer {access_token}
```

**令牌有效期**：
- **访问令牌 (Access Token)**: 5分钟
- **刷新令牌 (Refresh Token)**: 1天

### 通用响应格式

所有 API 响应均遵循以下格式：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | 状态码，200表示成功，其他表示错误 |
| msg | string | 响应消息 |
| data | object/any | 响应数据，具体结构视接口而定 |

---

## 用户管理 API

### 1. 用户注册

创建新用户账户，需要通过邮箱验证码验证。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/register` |
| HTTP 方法 | POST |
| 认证要求 | 无需认证 |
| Content-Type | multipart/form-data |

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|------|
| user_name | string | formData | 是 | 用户名，唯一标识符 | "john_doe" |
| password | string | formData | 是 | 密码，8-32位 | "Password123!" |
| email | string | formData | 是 | 邮箱地址 | "user@example.com" |
| verification_code | string | formData | 是 | 邮箱验证码 | "123456" |

**密码要求**：
- 长度：8-32 个字符
- 必须包含大写字母 (A-Z)
- 必须包含小写字母 (a-z)
- 必须包含数字 (0-9)
- 必须包含特殊字符：`!@#$%^&*(),.?":{}|<>`
- 不能包含空格
- 不能包含用户名

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "注册成功",
  "data": null
}
```

错误响应示例：
```json
{
  "code": 20205,
  "msg": "用户已存在",
  "data": null
}
```

```json
{
  "code": 20217,
  "msg": "验证码无效",
  "data": null
}
```

```json
{
  "code": 20005,
  "msg": "密码格式校验失败",
  "data": null
}
```

---

### 2. 用户登录

用户登录验证，成功后返回访问令牌和刷新令牌。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/login` |
| HTTP 方法 | POST |
| 认证要求 | 无需认证 |
| Content-Type | multipart/form-data |

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|------|
| account | string | formData | 是 | 用户名/邮箱/手机号 | "john_doe" |
| password | string | formData | 是 | 密码 | "Password123!" |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "登录成功",
  "data": {
    "success": true,
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "user_name": "john_doe",
      "nickname": "John Doe",
      "email": "user@example.com",
      "phone": "",
      "avatar": "",
      "bio": "",
      "website": "",
      "location": "",
      "birthday": "",
      "gender": "",
      "is_locked": false,
      "lock_until": "0001-01-01T00:00:00Z",
      "daily_photographs": [],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    },
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

错误响应示例：
```json
{
  "code": 20204,
  "msg": "密码错误",
  "data": {
    "success": false
  }
}
```

```json
{
  "code": 20214,
  "msg": "用户已被锁定",
  "data": {
    "success": false
  }
}
```

```json
{
  "code": 20216,
  "msg": "用户已被封禁",
  "data": {
    "success": false
  }
}
```

---

### 3. 刷新访问令牌

使用刷新令牌获取新的访问令牌和刷新令牌。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/refreshToken` |
| HTTP 方法 | POST |
| 认证要求 | 无需认证 |
| Content-Type | application/json |

**请求参数**

```json
{
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

| 参数名 | 类型 | 位置 | 必填 | 描述 |
|--------|------|------|------|------|
| refresh_token | string | body | 是 | 刷新令牌 |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "令牌刷新成功",
  "data": {
    "success": true,
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "user_name": "john_doe",
      "nickname": "John Doe",
      "email": "user@example.com"
    },
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

错误响应示例：
```json
{
  "code": 20107,
  "msg": "Refresh token无效",
  "data": {
    "success": false
  }
}
```

```json
{
  "code": 20108,
  "msg": "Refresh token已过期",
  "data": {
    "success": false
  }
}
```

---

### 4. 验证访问令牌

验证当前访问令牌是否有效。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/validateAccessToken` |
| HTTP 方法 | GET / POST |
| 认证要求 | 需要 Bearer Token |
| Content-Type | application/json |

**请求头**

```
Authorization: Bearer {access_token}
```

**请求参数**

无需参数。

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "valid": true
  }
}
```

错误响应示例：
```json
{
  "code": 20101,
  "msg": "Authorization不存在",
  "data": null
}
```

```json
{
  "code": 20103,
  "msg": "Token错误",
  "data": null
}
```

```json
{
  "code": 20104,
  "msg": "Token已过期",
  "data": null
}
```

---

### 5. 获取邮箱验证码

发送邮箱验证码，用于用户注册或验证邮箱。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/emailVerificationCode` |
| HTTP 方法 | GET |
| 认证要求 | 无需认证 |
| Content-Type | multipart/form-data |

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|------|
| email | string | query | 是 | 邮箱地址 | "user@example.com" |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": null
}
```

错误响应示例：
```json
{
  "code": 20213,
  "msg": "邮箱格式不正确",
  "data": null
}
```

```json
{
  "code": 20219,
  "msg": "发送邮件验证码失败",
  "data": null
}
```

**注意事项**：
- 验证码有效期为 5 分钟
- 每个邮箱每分钟只能发送一次验证码

---

### 6. 验证邮箱验证码

验证收到的邮箱验证码是否正确。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/verifyEmailVerificationCode` |
| HTTP 方法 | POST |
| 认证要求 | 无需认证 |
| Content-Type | multipart/form-data |

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|------|
| email | string | formData | 是 | 邮箱地址 | "user@example.com" |
| verification_code | string | formData | 是 | 验证码（6位数字） | "123456" |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": null
}
```

错误响应示例：
```json
{
  "code": 20217,
  "msg": "验证码无效",
  "data": null
}
```

```json
{
  "code": 20218,
  "msg": "验证码长度不正确",
  "data": null
}
```

---

### 7. 检查用户名是否存在

检查用户名是否已被注册。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/checkUserName` |
| HTTP 方法 | GET |
| 认证要求 | 无需认证 |
| Content-Type | application/json |

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|------|
| user_name | string | query | 是 | 要检查的用户名 | "john_doe" |

**响应示例**

用户名可用 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": null
}
```

用户名已存在 (错误)：
```json
{
  "code": 20205,
  "msg": "用户已存在",
  "data": null
}
```

---

### 8. 检查邮箱是否存在

检查邮箱是否已被注册。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/checkUserEmail` |
| HTTP 方法 | GET |
| 认证要求 | 无需认证 |
| Content-Type | application/json |

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 示例 |
|--------|------|------|------|------|------|
| email | string | query | 是 | 要检查的邮箱 | "user@example.com" |

**响应示例**

邮箱可用 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": null
}
```

邮箱已存在 (错误)：
```json
{
  "code": 20220,
  "msg": "邮箱已被注册",
  "data": null
}
```

---

### 9. 获取用户信息

获取当前登录用户的完整个人信息。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/profile` |
| HTTP 方法 | GET |
| 认证要求 | 需要 Bearer Token |
| Content-Type | application/json |

**请求头**

```
Authorization: Bearer {access_token}
```

**请求参数**

无需参数（用户ID从令牌中解析）。

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "success": true,
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "user_name": "john_doe",
      "nickname": "John Doe",
      "email": "user@example.com",
      "phone": "13800138000",
      "avatar": "https://example.com/avatar.jpg",
      "bio": "这是我的个人简介",
      "website": "https://mywebsite.com",
      "location": "北京",
      "birthday": "1990-01-01",
      "gender": "男",
      "is_locked": false,
      "lock_until": "0001-01-01T00:00:00Z",
      "daily_photographs": [],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z"
    }
  }
}
```

错误响应示例：
```json
{
  "code": 20202,
  "msg": "用户不存在",
  "data": null
}
```

---

### 10. 更新用户信息

更新当前登录用户的个人信息。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/profile` |
| HTTP 方法 | PUT |
| 认证要求 | 需要 Bearer Token |
| Content-Type | application/json |

**请求头**

```
Authorization: Bearer {access_token}
```

**请求参数**

```json
{
  "nickname": "新昵称",
  "email": "newemail@example.com",
  "phone": "13900139000",
  "bio": "更新后的个人简介",
  "website": "https://newwebsite.com",
  "location": "上海",
  "birthday": "1990-01-01",
  "gender": "女"
}
```

| 参数名 | 类型 | 位置 | 必填 | 描述 |
|--------|------|------|------|------|
| nickname | string | body | 否 | 昵称 |
| email | string | body | 否 | 邮箱地址 |
| phone | string | body | 否 | 手机号码 |
| bio | string | body | 否 | 个人简介（最多255字符） |
| website | string | body | 否 | 个人网站 |
| location | string | body | 否 | 所在地（最多100字符） |
| birthday | string | body | 否 | 生日，格式：YYYY-MM-DD |
| gender | string | body | 否 | 性别 |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "success": true,
    "message": "用户信息更新成功"
  }
}
```

错误响应示例：
```json
{
  "code": 10002,
  "msg": "Error occurred while binding the request body to the struct.",
  "data": null
}
```

```json
{
  "code": 20202,
  "msg": "用户不存在",
  "data": null
}
```

---

### 11. 上传头像

上传当前登录用户的头像图片。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/avatar` |
| HTTP 方法 | POST |
| 认证要求 | 需要 Bearer Token |
| Content-Type | multipart/form-data |

**请求头**

```
Authorization: Bearer {access_token}
```

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 描述 | 限制 |
|--------|------|------|------|------|------|
| avatar | file | formData | 是 | 头像文件 | 支持 jpg/jpeg/png/gif，最大 5MB |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "success": true,
    "message": "头像上传成功",
    "avatar_url": "/uploads/avatars/avatar_123e4567-e89b-12d3-a456-426614174000_photo.jpg"
  }
}
```

错误响应示例：
```json
{
  "code": 10002,
  "msg": "Error occurred while binding the request body to the struct.",
  "data": null
}
```

```json
{
  "code": 20202,
  "msg": "用户不存在",
  "data": null
}
```

---

### 12. 修改密码

修改当前登录用户的密码。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/password` |
| HTTP 方法 | PUT |
| 认证要求 | 需要 Bearer Token |
| Content-Type | application/json |

**请求头**

```
Authorization: Bearer {access_token}
```

**请求参数**

```json
{
  "old_password": "oldPassword123!",
  "new_password": "newPassword456!"
}
```

| 参数名 | 类型 | 位置 | 必填 | 描述 |
|--------|------|------|------|------|
| old_password | string | body | 是 | 原密码 |
| new_password | string | body | 是 | 新密码（需符合密码要求） |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "success": true,
    "message": "密码修改成功"
  }
}
```

错误响应示例：
```json
{
  "code": 20204,
  "msg": "密码错误",
  "data": null
}
```

```json
{
  "code": 20005,
  "msg": "密码格式校验失败",
  "data": null
}
```

---

### 13. 获取操作日志

获取当前登录用户的操作日志记录，支持分页和筛选。

**接口信息**

| 项目 | 说明 |
|------|------|
| 接口路径 | `/user/operation-logs` |
| HTTP 方法 | GET |
| 认证要求 | 需要 Bearer Token |
| Content-Type | application/json |

**请求头**

```
Authorization: Bearer {access_token}
```

**请求参数**

| 参数名 | 类型 | 位置 | 必填 | 默认值 | 描述 | 示例 |
|--------|------|------|------|--------|------|------|
| page | int | query | 否 | 1 | 页码 | 1 |
| page_size | int | query | 否 | 10 | 每页数量 | 20 |
| sort | string | query | 否 | created_at | 排序字段 | operation_time |
| order | string | query | 否 | desc | 排序方向（asc/desc） | desc |
| search | string | query | 否 | - | 搜索关键词 | "login" |

**响应示例**

成功响应 (200)：
```json
{
  "code": 200,
  "msg": "OK",
  "data": {
    "success": true,
    "data": {
      "logs": [
        {
          "id": "log-id-1",
          "user_id": "123e4567-e89b-12d3-a456-426614174000",
          "user_name": "john_doe",
          "operation_type": "login",
          "operation_desc": "用户登录",
          "request_ip": "192.168.1.1",
          "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
          "request_data": "",
          "response_data": "",
          "status": "success",
          "error_message": "",
          "operation_time": "2024-01-01T10:00:00Z",
          "created_at": "2024-01-01T10:00:00Z",
          "updated_at": "2024-01-01T10:00:00Z"
        }
      ],
      "total": 100,
      "page": 1,
      "page_size": 10
    },
    "message": "获取操作日志成功"
  }
}
```

---

## 数据模型

### 用户模型 (User)

| 字段 | 类型 | 描述 | 说明 |
|------|------|------|------|
| id | uuid | 用户ID | 主键，自动生成 |
| user_name | string | 用户名 | 唯一，必填 |
| password | string | 密码 | 加密存储，不返回给前端 |
| nickname | string | 昵称 | 默认为用户名 |
| email | string | 邮箱 | 必填 |
| phone | string | 手机号 | 暂不使用 |
| avatar | string | 头像URL | |
| bio | string | 个人简介 | 最多255字符 |
| website | string | 个人网站 | |
| location | string | 所在地 | 最多100字符 |
| birthday | string | 生日 | 格式：YYYY-MM-DD |
| gender | string | 性别 | |
| role | string | 角色 | admin/user/guest，不返回给前端 |
| status | string | 状态 | active/inactive/suspended，不返回给前端 |
| is_locked | bool | 是否锁定 | |
| lock_until | timestamp | 锁定截止时间 | |
| created_at | timestamp | 创建时间 | |
| updated_at | timestamp | 更新时间 | |

### 操作日志模型 (OperationLog)

| 字段 | 类型 | 描述 |
|------|------|------|
| id | uuid | 日志ID |
| user_id | uuid | 用户ID |
| user_name | string | 用户名 |
| operation_type | string | 操作类型 |
| operation_desc | string | 操作描述 |
| request_ip | string | 请求IP地址 |
| user_agent | string | 用户代理字符串 |
| request_data | string | 请求数据 |
| response_data | string | 响应数据 |
| status | string | 操作状态 |
| error_message | string | 错误信息 |
| operation_time | timestamp | 操作时间 |
| created_at | timestamp | 创建时间 |
| updated_at | timestamp | 更新时间 |

---

## 错误码参考

### 通用错误码 (10001-19999)

| 错误码 | 描述 |
|--------|------|
| 10001 | 内部服务器错误 |
| 10002 | 请求参数绑定失败 |
| 10003 | 参数有误 |
| 10004 | 签名参数有误 |

### 验证错误 (20001-20099)

| 错误码 | 描述 |
|--------|------|
| 20001 | 验证失败 |
| 20002 | 数据库错误 |
| 20003 | JWT签名错误 |
| 20004 | 无效事务 |
| 20005 | 密码格式校验失败 |
| 20006 | RSA密钥路径错误 |
| 20007 | RSA公钥路径错误 |

### JWT 相关错误 (20101-20199)

| 错误码 | 描述 |
|--------|------|
| 20101 | Authorization不存在 |
| 20102 | 生成JWT错误 |
| 20103 | Token错误 |
| 20104 | Token已过期 |
| 20105 | Token签发错误 |
| 20106 | Token生效时间错误 |
| 20107 | Refresh token无效 |
| 20108 | Refresh token已过期 |

### 用户相关错误 (20201-20299)

| 错误码 | 描述 |
|--------|------|
| 20201 | 密码加密错误 |
| 20202 | 用户不存在 |
| 20203 | 无效的用户ID |
| 20204 | 密码错误 |
| 20205 | 用户已存在 |
| 20206 | 用户创建错误 |
| 20207 | 已超出当日限制 |
| 20208 | 验证码错误 |
| 20209 | 邮箱或密码错误 |
| 20210 | 两次密码输入不一致 |
| 20211 | 注册失败 |
| 20212 | 用户创建失败 |
| 20213 | 邮箱格式不正确 |
| 20214 | 用户已被锁定 |
| 20215 | 用户未激活 |
| 20216 | 用户已被封禁 |
| 20217 | 验证码无效 |
| 20218 | 验证码长度不正确 |
| 20219 | 发送邮件验证码失败 |
| 20220 | 邮箱已被注册 |

### 文章相关错误 (20501-20599)

| 错误码 | 描述 |
|--------|------|
| 20501 | 文章标题不能为空 |
| 20502 | 文章内容不能为空 |
| 20503 | 文章用户ID不能为空 |
| 20504 | 文章状态无效 |
| 20505 | 文章不存在 |
| 20506 | 文章创建失败 |
| 20507 | 文章更新失败 |
| 20508 | 文章删除失败 |
| 20509 | 文章列表获取失败 |
| 20510 | 文章获取失败 |
| 20511 | 没有权限操作此文章 |
| 20512 | 封面图片必须是有效的URL或Base64编码的图片 |
| 20513 | 无效的文章ID |

### 评论相关错误 (20401-20499)

| 错误码 | 描述 |
|--------|------|
| 20401 | 评论创建失败 |
| 20402 | 评论列表获取失败 |

### 照片相关错误 (20301-20399)

| 错误码 | 描述 |
|--------|------|
| 20301 | 图片上传失败 |
| 20302 | 图片删除失败 |
| 20303 | 图片列表获取失败 |
| 20304 | 图片详情获取失败 |

### 每日照片相关错误 (20601-20699)

| 错误码 | 描述 |
|--------|------|
| 20601 | 用户不存在 |
| 20602 | 日期格式错误 |
| 20603 | 照片不存在 |
| 20604 | 无权限操作此照片 |
| 20605 | 创建照片失败 |
| 20606 | 更新照片失败 |
| 20607 | 删除照片失败 |
| 20608 | 点赞照片失败 |
| 20609 | 获取照片列表失败 |
| 20610 | 打开文件失败 |
| 20611 | 上传文件失败 |

---

## 使用示例

### 完整的用户注册流程

```bash
# 1. 检查用户名是否可用
curl -X GET "http://127.0.0.1:9997/api/v1/user/checkUserName?user_name=john_doe"

# 2. 检查邮箱是否可用
curl -X GET "http://127.0.0.1:9997/api/v1/user/checkUserEmail?email=user@example.com"

# 3. 获取邮箱验证码
curl -X GET "http://127.0.0.1:9997/api/v1/user/emailVerificationCode?email=user@example.com"

# 4. 验证邮箱验证码
curl -X POST "http://127.0.0.1:9997/api/v1/user/verifyEmailVerificationCode" \
  -F "email=user@example.com" \
  -F "verification_code=123456"

# 5. 注册用户
curl -X POST "http://127.0.0.1:9997/api/v1/user/register" \
  -F "user_name=john_doe" \
  -F "password=Password123!" \
  -F "email=user@example.com" \
  -F "verification_code=123456"
```

### 登录和访问受保护的资源

```bash
# 1. 用户登录
curl -X POST "http://127.0.0.1:9997/api/v1/user/login" \
  -F "account=john_doe" \
  -F "password=Password123!"

# 响应中会返回 access_token 和 refresh_token

# 2. 验证访问令牌
curl -X GET "http://127.0.0.1:9997/api/v1/user/validateAccessToken" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 3. 获取用户信息
curl -X GET "http://127.0.0.1:9997/api/v1/user/profile" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 4. 更新用户信息
curl -X PUT "http://127.0.0.1:9997/api/v1/user/profile" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nickname": "新昵称",
    "bio": "这是我的新简介"
  }'

# 5. 上传头像
curl -X POST "http://127.0.0.1:9997/api/v1/user/avatar" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "avatar=@/path/to/avatar.jpg"

# 6. 修改密码
curl -X PUT "http://127.0.0.1:9997/api/v1/user/password" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "old_password": "Password123!",
    "new_password": "NewPassword456!"
  }'

# 7. 获取操作日志
curl -X GET "http://127.0.0.1:9997/api/v1/user/operation-logs?page=1&page_size=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 8. 刷新令牌
curl -X POST "http://127.0.0.1:9997/api/v1/user/refreshToken" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'
```

---

## 限流规则

为保护系统安全，API 实施了以下限流规则：

| 接口类型 | 限流规则 | 时间窗口 |
|----------|----------|----------|
| 登录 | 每IP 5次 | 1分钟 |
| 注册 | 每IP 3次 | 1分钟 |
| 验证码 | 每邮箱 1次 | 1分钟 |
| 其他接口 | 每IP 100次 | 1分钟 |

超出限流阈值将返回 `429 Too Many Requests` 状态码。

---

## 注意事项

### 安全相关
1. **密码安全**：
   - 密码采用 bcrypt 加密存储
   - 建议使用强密码（8位以上，包含大小写字母、数字和特殊字符）
   - 不要在多个网站使用相同密码

2. **令牌管理**：
   - 访问令牌有效期较短（5分钟），需要定期刷新
   - 刷新令牌有效期较长（1天），应妥善保管
   - 令牌过期后需要重新登录

3. **HTTPS**：
   - 生产环境建议使用 HTTPS 协议
   - 确保 Authorization 头部不会被中间人攻击窃取

### 业务规则
1. **邮箱验证**：
   - 验证码有效期为 5 分钟
   - 每个邮箱每分钟只能发送一次验证码
   - 验证码为 6 位数字

2. **头像上传**：
   - 支持 jpg、jpeg、png、gif 格式
   - 文件大小不超过 5MB
   - 上传后会自动生成访问URL

3. **用户状态**：
   - 用户状态包括：active（激活）、inactive（未激活）、suspended（封禁）
   - 被封禁或锁定的用户无法登录
   - 连续登录失败可能导致账户被临时锁定

### 错误处理
1. 所有错误响应都包含明确的错误码和错误信息
2. 客户端应根据错误码进行相应的处理
3. 常见错误处理：
   - `20103`/`20104`：令牌无效或过期，需要重新登录或刷新令牌
   - `20204`：密码错误，检查用户名和密码
   - `20217`：验证码无效，重新获取验证码
   - `10002`：请求参数格式错误，检查请求参数

---

## 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2024-01-01 | 初始版本，包含用户管理所有API接口 |

---

## 技术支持

如有问题或建议，请通过以下方式联系：

- GitHub Issues: [项目地址]
- 邮箱: [联系邮箱]

---

**© 2024 DreamZero Blog. All rights reserved.**

# Perfect Turnstile 与 PostgreSQL 集成用户身份验证[English](README.md)

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involed with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>


该项目将 Stormpath 公司的 Turnstile 用户身份验证系统与 PostgreSQL 的数据库对象关系管理集成到了同一个软件函数库上。

## 安装

请在您的 Package.swift 文件中增加如下依存关系：

``` swift
.Package(
	url: "https://github.com/PerfectlySoft/Perfect-Turnstile-PostgreSQL.git",
	majorVersion: 0, minor: 0
	)
```

## 增加 JSON API 路由入口点

本项目依赖于以下基本路由：

```HTTP
POST /api/v1/login （包括带有用户名和密码的表单）
POST /api/v1/register （包括带有用户名和密码的表单）
GET /api/v1/logout
```

## 浏览器测试路由

以下 URL 可以用于浏览器测试：

```
http://localhost:8181
http://localhost:8181/login
http://localhost:8181/register
```

上述路由使用了 Mustache 文档模板，存放在 webroot 目录下。

关于 Mustache 文件模板的例子可以在这里找到： [https://github.com/PerfectExamples/Perfect-Turnstile-PostgreSQL-Demo](https://github.com/PerfectExamples/Perfect-Turnstile-PostgreSQL-Demo)

## 创建一个带有身份验证功能的 HTTP 服务器

``` swift 
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

import StORM
import PostgresStORM
import PerfectTurnstilePostgreSQL

// 如果希望调试SQL，则请把下一句话的注释去掉
//StORMdebug = true

// 下面这个变量在后续的Real对象程序脚本中将用于用户身份验证
let pturnstile = TurnstilePerfectRealm()

// 设置数据库连接变量
connect = PostgresConnect(
	host: "localhost",
	username: "perfect",
	password: "perfect",
	database: "perfect_testing",
	port: 32769
)

// // 设置身份验证表
let auth = AuthAccount(connect!)
auth.setup()

// 连接到令牌数据区
tokenStore = AccessTokenStore(connect!)
tokenStore?.setup()

// 创建 HTTP 服务器
let server = HTTPServer()

// 生成路由及其句柄
let authWebRoutes = makeWebAuthRoutes()
let authJSONRoutes = makeJSONAuthRoutes("/api/v1")

// 将路由器注册到服务器
server.addRoutes(authWebRoutes)
server.addRoutes(authJSONRoutes)

// 增加更多路由
var routes = Routes()
// routes.add(method: .get, uri: "/api/v1/test", handler: AuthHandlersJSON.testHandler)

// 将路由注册到服务器
server.addRoutes(routes)

// 增加用于身份验证的路由
var authenticationConfig = AuthenticationConfig()
authenticationConfig.include("/api/v1/check")
authenticationConfig.exclude("/api/v1/login")
authenticationConfig.exclude("/api/v1/register")

let authFilter = AuthFilter(authenticationConfig)

// 注意在相同优先级的情况下，过滤器的注册顺序决定了最终两个过滤器的优先顺序
server.setRequestFilters([pturnstile.requestFilter])
server.setResponseFilters([pturnstile.responseFilter])

server.setRequestFilters([(authFilter, .high)])

// 设置监听端口为
server.serverPort = 8181

// 设置静态文件根目录
server.documentRoot = "./webroot"

do {
	// 启动 HTTP 服务
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("网络异常： \(err) \(msg)")
}

```

### 基本要求

首先定义一下“域对象 Realm” —— 这是 Turnstile 定义的用户身份验证处理的管理方法。其实现方法是通过连接一个数据源（比如PostgreSQL）—— 其实各个数据源的连接方法都大同小异， 您可以自行参考，在此基础之上进行扩展。

``` swift 
let pturnstile = TurnstilePerfectRealm()
```

连接到 PostgresSQL 数据库：

``` swift
connect = PostgresConnect(
	host: "localhost",
	username: "perfect",
	password: "perfect",
	database: "perfect_testing",
	port: 32769
)
```

定义并初始化身份验证表：

``` swift 
let auth = AuthAccount(connect!)
auth.setup()
```

连接到令牌数据区：

``` swift
tokenStore = AccessTokenStore(connect!)
tokenStore?.setup()
```

启动 HTTP 服务器

``` swift
let server = HTTPServer()
```

创建路由和路由处理句柄，并将路由注册到服务器上：

``` swift 
let authWebRoutes = makeWebAuthRoutes()
let authJSONRoutes = makeJSONAuthRoutes("/api/v1")

server.addRoutes(authWebRoutes)
server.addRoutes(authJSONRoutes)
```

增加用于身份验证的路由：

``` swift
var authenticationConfig = AuthenticationConfig()
authenticationConfig.include("/api/v1/check")
authenticationConfig.exclude("/api/v1/login")
authenticationConfig.exclude("/api/v1/register")

let authFilter = AuthFilter(authenticationConfig)
```

输入路由的时候可以一个一个分别录入，或者整个儿做成一个数组一起放进去，可以把需要包含的路径和不希望包含的路径都分别进行登记处理。下一版的函数库允许使用通配符处理路径。

增加请求/响应的过滤器。注意如果不同过滤器的优先等级相同，则一定要处理好写程序的顺序，因为这种情况下程序顺序决定了最终路由表内过滤器的前后处理顺序：

``` swift
server.setRequestFilters([pturnstile.requestFilter])
server.setResponseFilters([pturnstile.responseFilter])

server.setRequestFilters([(authFilter, .high)])
```

随后可以设置监听端口、静态文件并最终启动服务器：

``` swift
// 设置监听端口 8181
server.serverPort = 8181

// 设置服务器静态文件根目录
server.documentRoot = "./webroot"

do {
	// 启动 HTTP 服务器
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("网络异常： \(err) \(msg)")
}
```

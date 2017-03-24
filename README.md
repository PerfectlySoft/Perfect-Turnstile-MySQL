# Perfect Turnstile with MySQL [简体中文](README.zh_CN.md)

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


This project integrates Stormpath's Turnstile authentication system into a single package with Perfect, and a PostgreSQL ORM.

## Installation

In your Package.swift file, include the following line inside the dependancy array:

``` swift
.Package(
	url: "https://github.com/PerfectlySoft/Perfect-Turnstile-PostgreSQL.git",
	majorVersion: 0, minor: 0
	)
```

## macOS

If you receive a compile error that says the following, you need to install and link libxml2

```
note: you may be able to install libxml-2.0 using your system-packager:

    brew install libxml2

Compile Swift Module 'PerfectXML' (2 sources)
<module-includes>:1:9: note: in file included from <module-includes>:1:
#import "libxml2.h"
```

To install and link libxml2 with homebrew, use the following two commands

```
brew install libxml2
brew link --force libxml2
```

To install Postgres:

```
brew install postgres
```

## Linux

Ensure that you have installed libxml2-dev and pkg-config.

```
sudo apt-get install libxml2-dev pkg-config
```

To install libpq-dev

```
sudo apt-get install libpq-dev
```

## Included JSON Routes

The framework includes certain basic routes:

```
POST /api/v1/login (with username & password form elements)
POST /api/v1/register (with username & password form elements)
GET /api/v1/logout
```

## Included Routes for Browser

The following routes are available for browser testing:

```
http://localhost:8181
http://localhost:8181/login
http://localhost:8181/register
```

These routes are using Mustache files in the webroot directory.

Example Mustache files can be found in [https://github.com/PerfectExamples/Perfect-Turnstile-PostgreSQL-Demo](https://github.com/PerfectExamples/Perfect-Turnstile-PostgreSQL-Demo)

## Creating an HTTP Server with Authentication

``` swift 
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

import StORM
import PostgresStORM
import PerfectTurnstilePostgreSQL

// uncomment to turn on SQL Logging to console
//StORMdebug = true

// Used later in script for the Realm and how the user authenticates.
let pturnstile = TurnstilePerfectRealm()

// Set the connection variable
connect = PostgresConnect(
	host: "localhost",
	username: "perfect",
	password: "perfect",
	database: "perfect_testing",
	port: 32769
)

// Set up the Authentication table
let auth = AuthAccount(connect!)
auth.setup()

// Connect the AccessTokenStore
tokenStore = AccessTokenStore(connect!)
tokenStore?.setup()

// Create HTTP server.
let server = HTTPServer()

// Register routes and handlers
let authWebRoutes = makeWebAuthRoutes()
let authJSONRoutes = makeJSONAuthRoutes("/api/v1")

// Add the routes to the server.
server.addRoutes(authWebRoutes)
server.addRoutes(authJSONRoutes)

// Add more routes here
var routes = Routes()
// routes.add(method: .get, uri: "/api/v1/test", handler: AuthHandlersJSON.testHandler)

// Add the routes to the server.
server.addRoutes(routes)

// add routes to be checked for auth
var authenticationConfig = AuthenticationConfig()
authenticationConfig.include("/api/v1/check")
authenticationConfig.exclude("/api/v1/login")
authenticationConfig.exclude("/api/v1/register")

let authFilter = AuthFilter(authenticationConfig)

// Note that order matters when the filters are of the same priority level
server.setRequestFilters([pturnstile.requestFilter])
server.setResponseFilters([pturnstile.responseFilter])

server.setRequestFilters([(authFilter, .high)])

// Set a listen port of 8181
server.serverPort = 8181

// Where to serve static files from
server.documentRoot = "./webroot"

do {
	// Launch the HTTP server.
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}

```

### Requirements

Define the "Realm" - this is the Turnstile definition of how the authentication is handled. The implementation is specific to the PostgreSQL datasource, although it is very similar between datasources and is designed to be generic and extendable.

``` swift 
let pturnstile = TurnstilePerfectRealm()
```

Define the connection details to access the PostgreSQL database:

``` swift
connect = PostgresConnect(
	host: "localhost",
	username: "perfect",
	password: "perfect",
	database: "perfect_testing",
	port: 32769
)
```

Define, and initialize up the authentication table:

``` swift 
let auth = AuthAccount(connect!)
auth.setup()
```

Connect the AccessTokenStore:

``` swift
tokenStore = AccessTokenStore(connect!)
tokenStore?.setup()
```

Create the HTTP Server:

``` swift
let server = HTTPServer()
```

Register routes and handlers and add the routes to the server:

``` swift 
let authWebRoutes = makeWebAuthRoutes()
let authJSONRoutes = makeJSONAuthRoutes("/api/v1")

server.addRoutes(authWebRoutes)
server.addRoutes(authJSONRoutes)
```

Add routes to be checked for authentication:

``` swift
var authenticationConfig = AuthenticationConfig()
authenticationConfig.include("/api/v1/check")
authenticationConfig.exclude("/api/v1/login")
authenticationConfig.exclude("/api/v1/register")

let authFilter = AuthFilter(authenticationConfig)
```

These routes can be either seperate, or as an array of strings. They describe inclusions and exclusions. In a forthcoming release wildcard routes will be supported.

Add request & response filters. Note the order which you specify filters that are of the same priority level:

``` swift
server.setRequestFilters([pturnstile.requestFilter])
server.setResponseFilters([pturnstile.responseFilter])

server.setRequestFilters([(authFilter, .high)])
```

Now, set the port, static files location, and start the server:

``` swift
// Set a listen port of 8181
server.serverPort = 8181

// Where to serve static files from
server.documentRoot = "./webroot"

do {
	// Launch the HTTP server.
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}
```


## Issues

We use JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)



## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).


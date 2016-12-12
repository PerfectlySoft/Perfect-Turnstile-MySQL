//
//  RoutingHandlers.swift
//  PerfectTurnstileMySQL
//
//  Created by Jonathan Guthrie on 2016-12-08.
//
//

import PerfectLib
import PerfectHTTP
import PerfectMustache

import TurnstilePerfect
import Turnstile
import TurnstileCrypto
import TurnstileWeb

/// The class that holds all the Web-oriented Authentication handlers
public class AuthHandlersWeb {
	/* =================================================================================================================
	Index
	================================================================================================================= */
	/// Handles the GET request for an "index" route
	open static func indexHandlerGet(request: HTTPRequest, _ response: HTTPResponse) {
		let context: [String : Any] = [
			"accountID": request.user.authDetails?.account.uniqueID ?? "",
			"authenticated": request.user.authenticated
		]
		response.render(template: "index", context: context)

	}
	/* =================================================================================================================
	/Index
	================================================================================================================= */


	/* =================================================================================================================
	Login
	================================================================================================================= */
	/// Handles the GET request for a "login" route
	open static func loginHandlerGET(request: HTTPRequest, _ response: HTTPResponse) {
		response.render(template: "login")
	}


	/// Handles the POST request for a "login" route
	open static func loginHandlerPOST(request: HTTPRequest, _ response: HTTPResponse) {
		guard let username = request.param(name: "username"),
			let password = request.param(name: "password") else {
				response.render(template: "login", context:  ["flash": "Missing username or password"])
				return
		}
		let credentials = UsernamePassword(username: username, password: password)

		do {
			try request.user.login(credentials: credentials, persist: true)
			response.redirect(path: "/")
		} catch {
			response.render(template: "login", context: ["flash": "Invalid Username or Password"])
		}
	}
	/* =================================================================================================================
	/Login
	================================================================================================================= */



	/* =================================================================================================================
	Register
	================================================================================================================= */
	/// Handles the GET request for a "register" route
	open static func registerHandlerGET(request: HTTPRequest, _ response: HTTPResponse) {
		response.render(template: "register")
	}
	/// Handles the POST request for a "register" route
	open static func registerHandlerPOST(request: HTTPRequest, _ response: HTTPResponse) {
		guard let username = request.param(name: "username"),
			let password = request.param(name: "password") else {
				response.render(template: "register", context: ["flash": "Missing username or password"])
				return
		}
		let credentials = UsernamePassword(username: username, password: password)

		do {
			try request.user.register(credentials: credentials)
			try request.user.login(credentials: credentials, persist: true)
			response.redirect(path: "/")
		} catch let e as TurnstileError {
			response.render(template: "register", context: ["flash": e.description])
		} catch {
			response.render(template: "register", context: ["flash": "An unknown error occurred."])
		}
	}
	/* =================================================================================================================
	/Register
	================================================================================================================= */




	/* =================================================================================================================
	Logout
	================================================================================================================= */
	/// Handles the request for a "logout" route
	open static func logoutHandler(request: HTTPRequest, _ response: HTTPResponse) {
		response.addCookie(HTTPCookie(name: "TurnstileSession",
									value: "\(request.user.authDetails?.sessionID)",
									domain: nil,
									expires: .relativeSeconds(-1),
									path: "/",
									secure: nil,
									httpOnly: true))

		request.user.logout()

		response.redirect(path: "/")
	}
	/* =================================================================================================================
	/Logout
	================================================================================================================= */



	/* =================================================================================================================
	Facebook Signin
	================================================================================================================= */
//	open static func facebookHandler(request: HTTPRequest, _ response: HTTPResponse) {
//		let state = URandom().secureToken
//		let redirectURL = facebook.getLoginLink(redirectURL: "http://localhost:8181/login/facebook/consumer", state: state)
//
//		response.addCookie(HTTPCookie(name: "OAuthState", value: state, domain: nil, expires: HTTPCookie.Expiration.relativeSeconds(3600), path: "/", secure: nil, httpOnly: true))
//		response.redirect(path: redirectURL.absoluteString)
//	}
//	open static func facebookHandlerConsumer(request: HTTPRequest, _ response: HTTPResponse) {
//		guard let state = request.cookies.filter({$0.0 == "OAuthState"}).first?.1 else {
//			response.render(template: "login", context: ["flash": "Unknown Error"])
//			return
//		}
//		response.addCookie(HTTPCookie(name: "OAuthState", value: state, domain: nil, expires: HTTPCookie.Expiration.absoluteSeconds(0), path: "/", secure: nil, httpOnly: true))
//		let uri = "http://localhost:8181" + request.uri
//
//		do {
//			let credentials = try facebook.authenticate(authorizationCodeCallbackURL: uri, state: state) as! FacebookAccount
//			try request.user.login(credentials: credentials, persist: true)
//			response.redirect(path: "/")
//		} catch let error {
//			let description = (error as? TurnstileError)?.description ?? "Unknown Error"
//			response.render(template: "login", context: ["flash": description])
//		}
//	}
	/* =================================================================================================================
	/Facebook Signin
	================================================================================================================= */



	/* =================================================================================================================
	Google Signin
	================================================================================================================= */
//	open static func googleHandler(request: HTTPRequest, _ response: HTTPResponse) {
//		let state = URandom().secureToken
//		let redirectURL = google.getLoginLink(redirectURL: "http://localhost:8181/login/google/consumer", state: state)
//
//		response.addCookie(HTTPCookie(name: "OAuthState", value: state, domain: nil, expires: nil, path: "/", secure: nil, httpOnly: true))
//		response.redirect(path: redirectURL.absoluteString)
//	}
//	open static func googleHandlerConsumer(request: HTTPRequest, _ response: HTTPResponse) {
//		guard let state = request.cookies.filter({$0.0 == "OAuthState"}).first?.1 else {
//			response.render(template: "login", context: ["flash": "Unknown Error"])
//			return
//		}
//		response.addCookie(HTTPCookie(name: "OAuthState", value: state, domain: nil, expires: HTTPCookie.Expiration.absoluteSeconds(0), path: "/", secure: nil, httpOnly: true))
//		let uri = "http://localhost:8181" + request.uri
//
//		do {
//			let credentials = try google.authenticate(authorizationCodeCallbackURL: uri, state: state) as! GoogleAccount
//			try request.user.login(credentials: credentials, persist: true)
//			response.redirect(path: "/")
//		} catch let error {
//			let description = (error as? TurnstileError)?.description ?? "Unknown Error"
//			response.render(template: "login", context: ["flash": description])
//		}
//	}
	/* =================================================================================================================
	/Google Signin
	================================================================================================================= */
}

//
//  AuthHandlersJSON.swift
//  PerfectTurnstileMySQL
//
//  Created by Jonathan Guthrie on 2016-12-08.
//
//

import PerfectLib
import PerfectHTTP
import PerfectMustache
import StORM
import MySQL
import MySQLStORM
import Foundation

import TurnstilePerfect
import Turnstile
import TurnstileCrypto
import TurnstileWeb

#if os(Linux)
    import SwiftGlibc
#else
    import Darwin
#endif


/// public var that houses the Token object
public var tokenStore: AccessTokenStore?

/// The class that holds all the JSON Authentication handlers
public class AuthHandlersJSON {


	/* =================================================================================================================
	Login
	================================================================================================================= */
	/// JSON Login action (POST)
	open static func loginHandlerPOST(request: HTTPRequest, _ response: HTTPResponse) {
		response.setHeader(.contentType, value: "application/json")

		var resp = [String: String]()
		guard let username = request.param(name: "username"),
			let password = request.param(name: "password") else {
				resp["error"] = "Missing username or password"
				do {
					try response.setBody(json: resp)
				} catch {
					print(error)
				}
				response.completed()
				return
		}
		let credentials = UsernamePassword(username: username, password: password)

		do {
			try request.user.login(credentials: credentials)

			let token = tokenStore?.new((request.user.authDetails?.account.uniqueID)!)

			resp["error"] = "none"
			resp["login"] = "ok"
			resp["token"] = token
            
            if let authAccount = request.user.authDetails?.account as? AuthAccount {
                resp["xmpp_un"] = authAccount._xmpp_un
                resp["xmpp_pw"] = authAccount._xmpp_pw
            }
            
		} catch {
			resp["error"] = "Invalid username or password"
		}
		do {
			try response.setBody(json: resp)
		} catch {
			print(error)
		}
		response.completed()
	}
	/* =================================================================================================================
	/Login
	================================================================================================================= */



	/* =================================================================================================================
	Register
	================================================================================================================= */
	/// JSON Register action (POST)
	open static func registerHandlerPOST(request: HTTPRequest, _ response: HTTPResponse) {
		response.setHeader(.contentType, value: "application/json")
		var resp = [String: String]()

		guard let username = request.param(name: "username"),
			let password = request.param(name: "password") else {
				resp["error"] = "Missing username or password"
				do {
					try response.setBody(json: resp)
				} catch {
					print(error)
				}
				response.completed()
				return
		}
		let credentials = UsernamePassword(username: username, password: password)

		do {
			try request.user.register(credentials: credentials)
            
            // if the registeration is good, register for the xmpp as well
            if let authAccount = request.user.authDetails?.account as? AuthAccount {
                
                // now register for the xmpp server using ejablibswiftCore.soberdctl
                let res = try runProc(cmd: "ejabberdctl", args: ["register",username, "localhost", password])
                Log.info(message: "Ejabberdctl result:\(res)")
                
                // using the returned data, update the just created ejabberd user with
                // foreign key of people_uniqueID

                let server = MySQL()
                let conn =  server.connect(host: MySQLConnector.host , user: MySQLConnector.username, password: MySQLConnector.password, db: MySQLConnector.database, port: UInt32(MySQLConnector.port))
                
                if conn {
                    
                    let sql = "UPDATE users SET people_uniqueID = '\(authAccount.uniqueID)' WHERE username = '\(authAccount.username)'"
                    if server.query(statement: sql) {
                        Log.info(message: "Successfull update")
                    } else {
                        Log.warning(message: "Update issue")
                    }
                    
                    defer { server.close() }
                    
                } else {
                    Log.warning(message: "Issue with opening:\(server.errorMessage())")
                }
            }
            
            // login as you go and send the user the info
			try request.user.login(credentials: credentials)
            
			//register
			resp["error"] = "none"
			resp["login"] = "ok"
			resp["token"] = response.request.user.authDetails?.sessionID
            
            if let authAccount = request.user.authDetails?.account as? AuthAccount {
                resp["xmpp_un"] = authAccount._xmpp_un
                resp["xmpp_pw"] = authAccount._xmpp_pw
            }
            
		} catch let e as TurnstileError {
			resp["error"] = e.description
        } catch let e as PerfectError {
            if case .systemError(let (_,text)) = e {
                Log.debug(message: text)
                resp["error"] = text
            }
            resp["error"] = "An unknown error occurred. \(e.localizedDescription)"
		} catch let e {
            Log.debug(message: e.localizedDescription)
            resp["error"] = e.localizedDescription
        }
        
		do {
			try response.setBody(json: resp)
		} catch {
			print(error)
		}
		response.completed()
	}
	/* =================================================================================================================
	/Register
	================================================================================================================= */




	/* =================================================================================================================
	Logout
	================================================================================================================= */
	/// JSON Logout action
	open static func logoutHandler(request: HTTPRequest, _ response: HTTPResponse) {
		response.setHeader(.contentType, value: "application/json")
		var resp = [String: String]()

        // Destroy the token and clean the token store
        if let headerValue = request.header(HTTPRequestHeader.Name.authorization) {
            if let res = tokenStore?.destroy(headerValue), !res {
                Log.warning(message: "Couldn't delete token from the store")
            }
        }
        
		request.user.logout()
		resp["error"] = "none"
		resp["logout"] = "complete"

		do {
			try response.setBody(json: resp)
		} catch {
			print(error)
		}
		response.completed()
	}
	/* =================================================================================================================
	/Logout
	================================================================================================================= */



	/* =================================================================================================================
	Facebook Signin
	================================================================================================================= */
//	open static func facebookHandler(request: HTTPRequest, _ response: HTTPResponse) {
//		response.setHeader(.contentType, value: "application/json")
//		var resp = [String: String]()
//
//		let state = URandom().secureToken
//		let redirectURL = facebook.getLoginLink(redirectURL: "http://localhost:8181/login/facebook/consumer", state: state)
//
//		response.addCookie(HTTPCookie(name: "OAuthState", value: state, domain: nil, expires: HTTPCookie.Expiration.relativeSeconds(3600), path: "/", secure: nil, httpOnly: true))
//		response.redirect(path: redirectURL.absoluteString)
//	}
//	open static func facebookHandlerConsumer(request: HTTPRequest, _ response: HTTPResponse) {
//		response.setHeader(.contentType, value: "application/json")
//		var resp = [String: String]()
//
//		guard let state = request.cookies.filter({$0.0 == "OAuthState"}).first?.1 else {
//			resp["error"] = "unknown error"
//			do {
//				try response.setBody(json: resp)
//			} catch {
//				print(error)
//			}
//			response.completed()
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
//			resp["error"] = description
//			do {
//				try response.setBody(json: resp)
//			} catch {
//				print(error)
//			}
//			response.completed()
//		}
//	}
	/* =================================================================================================================
	/Facebook Signin
	================================================================================================================= */



	/* =================================================================================================================
	Google Signin
	================================================================================================================= */
//	open static func googleHandler(request: HTTPRequest, _ response: HTTPResponse) {
//		response.setHeader(.contentType, value: "application/json")
//		var resp = [String: String]()
//
//		let state = URandom().secureToken
//		let redirectURL = google.getLoginLink(redirectURL: "http://localhost:8181/login/google/consumer", state: state)
//
//		response.addCookie(HTTPCookie(name: "OAuthState", value: state, domain: nil, expires: nil, path: "/", secure: nil, httpOnly: true))
//		response.redirect(path: redirectURL.absoluteString)
//	}
//	open static func googleHandlerConsumer(request: HTTPRequest, _ response: HTTPResponse) {
//		response.setHeader(.contentType, value: "application/json")
//		var resp = [String: String]()
//
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
//			resp["error"] = description
//			do {
//				try response.setBody(json: resp)
//			} catch {
//				print(error)
//			}
//			response.completed()
//		}
//	}
	/* =================================================================================================================
	/Google Signin
	================================================================================================================= */




	/// Allows a simple route handler for checking if the user is still logged in.
	open static func testHandler(request: HTTPRequest, _ response: HTTPResponse) {
		response.setHeader(.contentType, value: "application/json")

		var resp = [String: String]()

		resp["authenticated"] = "AUTHED: \(request.user.authenticated)"
		resp["authDetails"] = "DETAILS: \(request.user.authDetails)"


		do {
			try response.setBody(json: resp)
		} catch {
			print(error)
		}
		response.completed()
	}
    
    private static func runProc(cmd: String, args: [String], read: Bool = false) throws -> String? {
        let envs = [("PATH", "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin")]
        let proc = try SysProcess(cmd, args: args, env: envs)
        var ret: String?
        if read {
            var ary = [UInt8]()
            while true {
                do {
                    guard let s = try proc.stdout?.readSomeBytes(count: 1024), s.count > 0 else {
                        break
                    }
                    ary.append(contentsOf: s)
                } catch PerfectLib.PerfectError.fileError(let code, _) {
                    if code != EINTR {
                        break
                    }
                }
            }
            ret = UTF8Encoding.encode(bytes: ary)
        }
        let res = try proc.wait(hang: true)
        if res != 0 {
            let s = try proc.stderr?.readString()
            throw  PerfectError.systemError(Int32(res), s!)
        }
        return ret
    }

}

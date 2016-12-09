//
//  Account.swift
//  PerfectTurnstileMySQL
//
//  Created by Jonathan Guthrie on 2016-12-08.
//
//

import Turnstile
import TurnstileCrypto
import MySQLStORM
import StORM

open class AuthAccount : MySQLStORM, Account {
	public var uniqueID: String = ""

	public var username: String = ""
	public var password: String = ""

	public var facebookID: String = ""
	public var googleID: String = ""

	public var firstname: String = ""
	public var lastname: String = ""
	public var email: String = ""

	public var internal_token: AccessTokenStore = AccessTokenStore()

	override open func table() -> String {
		return "users"
	}

	public func id(_ newid: String) {
		uniqueID = newid
	}

	// Need to do this because of the nature of Swift's introspection
	override open func to(_ this: StORMRow) {
		uniqueID	= this.data["uniqueID"] as? String ?? ""
		username	= this.data["username"] as? String ?? ""
		password	= this.data["password"] as? String ?? ""
		facebookID	= this.data["facebookID"] as? String ?? ""
		googleID	= this.data["googleID"] as? String ?? ""
		firstname	= this.data["firstname"] as? String ?? ""
		lastname	= this.data["lastname"] as? String ?? ""
		email		= this.data["email"] as? String ?? ""
	}

	public func rows() -> [AuthAccount] {
		var rows = [AuthAccount]()
		for i in 0..<self.results.rows.count {
			let row = AuthAccount()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}

	func make() throws {
		do {
			password = BCrypt.hash(password: password)
			try create() // can't use save as the id is populated
		} catch {
			print(error)
		}
	}
	func get(_ un: String, _ pw: String) throws -> AuthAccount {
		let cursor = StORMCursor(limit: 1, offset: 0)
		do {
			try select(whereclause: "username = ?", params: [un], orderby: [], cursor: cursor)
			if self.results.rows.count == 0 {
				throw StORMError.noRecordFound
			}
			to(self.results.rows[0])
		} catch {
			print(error)
			throw StORMError.noRecordFound
		}
		if try BCrypt.verify(password: pw, matchesHash: password) {
			return self
		} else {
			throw StORMError.noRecordFound
		}

	}
	func exists(_ un: String) -> Bool {
		do {
			try select(whereclause: "username = ?", params: [un], orderby: [], cursor: StORMCursor(limit: 1, offset: 0))
			if results.rows.count == 1 {
				return true
			} else {
				return false
			}
		} catch {
			print("Exists error: \(error)")
			return false
		}
	}
}



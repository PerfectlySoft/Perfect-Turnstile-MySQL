//
//  Tokens.swift
//  PerfectTurnstileMySQL
//
//  Created by Jonathan Guthrie on 2016-12-08.
//
//

import MySQLStORM
import StORM
import Foundation
import SwiftRandom
import Turnstile



open class AccessTokenStore : MySQLStORM {

	var token: String = ""
	var userid: String = ""
	var created: Int = 0
	var updated: Int = 0
	var idle: Int = 86400 // 86400 seconds = 1 day

	override open func table() -> String {
		return "tokens"
	}


	// Need to do this because of the nature of Swift's introspection
	open override func to(_ this: StORMRow) {
		if let val = this.data["token"]		{ token		= val as! String }
		if let val = this.data["userid"]	{ userid	= val as! String }
		if let val = this.data["created"]	{ created	= val as! Int }
		if let val = this.data["updated"]	{ updated	= val as! Int }
		if let val = this.data["idle"]		{ idle		= val as! Int}

	}

	func rows() -> [AccessTokenStore] {
		var rows = [AccessTokenStore]()
		for i in 0..<self.results.rows.count {
			let row = AccessTokenStore()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}

	private func now() -> Int {
		return Int(Date.timeIntervalSinceReferenceDate)
	}

	// checks to see if the token is active
	// upticks the updated int to keep it alive.
	public func check() -> Bool? {
		if (updated + idle) < now() { return false } else {
			do {
				updated = now()
				try save()
			} catch {
				print(error)
			}
			return true
		}
	}

	public func new(_ u: String) -> String {
		let rand = URandom()
		token = rand.secureToken
		token = token.replacingOccurrences(of: "-", with: "a")
		userid = u
		created = now()
		updated = now()
		do {
			try create()
		} catch {
			print(error)
		}
		return token
	}
}

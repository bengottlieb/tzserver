//
//  Token.swift
//  App
//
//  Created by Ben Gottlieb on 5/25/18.
//

import Foundation
import Vapor
import FluentSQLite
import Crypto
import Authentication

final class Token: Codable {
	var id: Int?
	var token: String
	var userID: User.ID
	
	init(token: String, userID: User.ID) {
		self.token = token
		self.userID = userID
	}
}

extension Token: SQLiteModel {}
extension Token: Migration {}
extension Token: Content {}
extension Token: Model {}

extension Token {
	var user: Parent<Token, User> {
		return parent(\.userID)
	}
	
	static func generate(for user: User) throws -> Token {
		let random = try CryptoRandom().generateData(count: 16)
		return try Token(token: random.base64EncodedString(), userID: user.requireID())
	}
}

extension Token: Authentication.Token {
	static let userIDKey: UserIDKey = \Token.userID
	typealias UserType = User
	typealias UserIDType = User.ID
}

extension Token: BearerAuthenticatable {
	static let tokenKey: TokenKey = \Token.token
}

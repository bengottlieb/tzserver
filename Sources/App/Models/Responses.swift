//
//  Responses.swift
//  App
//
//  Created by Ben Gottlieb on 5/26/18.
//

import Foundation
import FluentSQLite
import Vapor
import Authentication

final class ExistsPayload: Codable, Content {
	var exists: Bool
	
	init(user: User?) {
		self.exists = user != nil
	}
}

final class TokenPayload: Codable, Content {
	var token: String?
	
	init(user: User, from req: Request) throws {
		let token = try Token.generate(for: user)
		self.token = token.token
		_ = token.save(on: req)

	}
}

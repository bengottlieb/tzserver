//
//  User.Public.swift
//  App
//
//  Created by Ben Gottlieb on 5/25/18.
//

import FluentSQLite
import Vapor

extension User {
	var `public`: Public { return User.Public(self) }
	
	final class Public: Codable {
		var permissions: Permission
		var name: String?
		var id: Int?
		var imageURL: URL?
		var imageData: Data?
		var identity: Identity.Public?
		var emailIsVerified: Bool?
		var lockedOut: Bool?
		var wrongPasswordCount: Int?

		init(_ user: User) {
			self.name = user.name
			self.id = user.id
			self.permissions = user.permissions
			self.identity = user.identity.public
			self.emailIsVerified = user.emailIsVerified ?? true
			self.wrongPasswordCount = user.wrongPasswordCount ?? 0
			self.lockedOut = user.lockedOut ?? false
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKey.self)
			
			self.name = try container.decodeIfPresent(String.self, forKey: .name)
			self.id = try container.decodeIfPresent(Int.self, forKey: .id)
			self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
			if let url = try container.decodeIfPresent(String.self, forKey: .imageURL) {
				self.imageURL = URL(string: url)
			}
			if let permissions = try container.decodeIfPresent(String.self, forKey: .permissions) {
				self.permissions = Permission(rawValue: permissions) ?? .user
			} else {
				self.permissions = .user
			}
			self.identity = try container.decodeIfPresent(Identity.Public.self, forKey: .identity)
			self.emailIsVerified = try container.decodeIfPresent(Bool.self, forKey: .emailIsVerified) ?? false
			self.lockedOut = try container.decodeIfPresent(Bool.self, forKey: .lockedOut) ?? false
			self.wrongPasswordCount = try container.decodeIfPresent(Int.self, forKey: .wrongPasswordCount) ?? 0
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKey.self)
			if let name = self.name { try container.encode(name, forKey: .name) }
			try container.encode(self.id, forKey: .id)
			if let image = self.imageData { try container.encode(image, forKey: .imageData) }
			if let url = self.imageURL?.absoluteString { try container.encode(url, forKey: .imageURL) }
			try container.encode(self.permissions.rawValue, forKey: .permissions)
			try container.encode(self.identity, forKey: .identity)
			try container.encode(self.lockedOut, forKey: .lockedOut)
			try container.encode(self.wrongPasswordCount, forKey: .wrongPasswordCount)
			try container.encode(self.emailIsVerified, forKey: .emailIsVerified)
		}
	}
}

extension User.Public: SQLiteModel {
	static let entity = User.entity
}

extension User.Public: Content {}
extension User.Public: Parameter {}



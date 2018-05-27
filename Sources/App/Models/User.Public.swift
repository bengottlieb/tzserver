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
		var image: Data?
		var identity: Identity.Public?

		init(_ user: User) {
			self.name = user.name
			self.id = user.id
			self.permissions = user.permissions
			self.identity = user.identity.public
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKey.self)
			
			self.name = try container.decodeIfPresent(String.self, forKey: .name)
			self.id = try container.decodeIfPresent(Int.self, forKey: .id)
			self.image = try container.decodeIfPresent(Data.self, forKey: .image)
			if let url = try container.decodeIfPresent(String.self, forKey: .imageURL) {
				self.imageURL = URL(string: url)
			}
			if let permissions = try container.decodeIfPresent(String.self, forKey: .permissions) {
				self.permissions = Permission(rawValue: permissions) ?? .user
			} else {
				self.permissions = .user
			}
			self.identity = try container.decodeIfPresent(Identity.Public.self, forKey: .identity)
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKey.self)
			if let name = self.name { try container.encode(name, forKey: .name) }
			try container.encode(self.id, forKey: .id)
			if let image = self.image { try container.encode(image, forKey: .image) }
			if let url = self.imageURL?.absoluteString { try container.encode(url, forKey: .imageURL) }
			try container.encode(self.permissions.rawValue, forKey: .permissions)
			try container.encode(self.identity, forKey: .identity)
		}
	}
}

extension User.Public: SQLiteModel {
	static let entity = User.entity
}

extension User.Public: Content {}
extension User.Public: Parameter {}



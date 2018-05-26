//
//  User.Public.swift
//  App
//
//  Created by Ben Gottlieb on 5/25/18.
//

import FluentSQLite
import Vapor

extension User {
	final class Public: Codable {
		var permissions: Permission
		var name: String?
		var id: Int?
		var imageURL: URL?
		var image: Data?
		enum CodableKey: CodingKey { case id, name, permissions, image, imageURL }

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
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKey.self)
			if let name = self.name { try container.encode(name, forKey: .name) }
			try container.encode(self.id, forKey: .id)
			if let image = self.image { try container.encode(image, forKey: .image) }
			if let url = self.imageURL?.absoluteString { try container.encode(url, forKey: .imageURL) }
			try container.encode(self.permissions.rawValue, forKey: .permissions)
		}
	}
}

extension User.Public: SQLiteModel {
	static let entity = User.entity
}

extension User.Public: Content {}
extension User.Public: Parameter {}



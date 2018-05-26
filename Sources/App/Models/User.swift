import FluentSQLite
import Vapor

/// A single entry of a User list.
final class User: Codable {
	enum Permission: String, Codable { case user, manager, admin }
	enum CodableKey: CodingKey { case identity, id, name, permissions, image, imageURL }
	
	var identity: Identity
	var id: Int?
	var name: String?
	var permissions: Permission
	var image: Data?
	var imageURL: URL?
	
	init(identity: Identity, name: String? = nil, permissions: Permission = .user) {
		self.identity = identity
		self.name = name
		self.permissions = permissions
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodableKey.self)
		
		self.name = try container.decodeIfPresent(String.self, forKey: .name)
		self.identity = try container.decode(Identity.self, forKey: .identity)
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
		try container.encode(self.identity, forKey: .identity)
		try container.encode(self.id, forKey: .id)
		if let image = self.image { try container.encode(image, forKey: .image) }
		if let url = self.imageURL?.absoluteString { try container.encode(url, forKey: .imageURL) }
		try container.encode(self.permissions.rawValue, forKey: .permissions)
	}

	var timezones: [Timezone] { return [] }
}

extension User: SQLiteModel {
}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration { }

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }


import FluentSQLite
import Vapor

/// A single entry of a User list.
final class User: Codable {
//	enum Permission: String, Codable { case user, manager, admin }

	var id: Int?
	var name: String?
	var password: String			//just a hash
	var email: String
//	var permissions: Permission
	var image: Data?
	var imageURL: String?
	
	init(email: String, password: String) {
		self.email = email
		self.password = password
	//	self.permissions = permissions
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

import FluentSQLite
import Vapor
import Authentication

/// A single entry of a User list.
final class User: Codable {
	enum Permission: String, Codable { case user, manager, admin }
	enum CodableKey: CodingKey { case identity, id, name, permissions, image, imageURL, authenticationUsername, authenticationPassword }
	
	var identity: Identity
	var id: Int?
	var name: String?
	var permissions: Permission
	var image: Data?
	var imageURL: URL?
	
	
	var authenticationUsername: String = ""
	var authenticationPassword: String = ""

	init(identity: Identity, name: String? = nil, permissions: Permission = .user) {
		self.identity = identity
		self.name = name
		self.permissions = permissions
		self.authenticationPassword = identity.authenticationPassword
		self.authenticationUsername = identity.authenticationUsername
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
//		self.authenticationPassword = self.identity.authenticationPassword
//		self.authenticationUsername = self.identity.authenticationUsername
		
		self.authenticationUsername = try container.decodeIfPresent(String.self, forKey: .authenticationUsername) ?? self.identity.authenticationUsername
		self.authenticationPassword = try container.decodeIfPresent(String.self, forKey: .authenticationPassword) ?? self.identity.authenticationPassword
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodableKey.self)
		if let name = self.name { try container.encode(name, forKey: .name) }
		try container.encode(self.identity, forKey: .identity)
		try container.encode(self.id, forKey: .id)
		if let image = self.image { try container.encode(image, forKey: .image) }
		if let url = self.imageURL?.absoluteString { try container.encode(url, forKey: .imageURL) }
		try container.encode(self.permissions.rawValue, forKey: .permissions)
		
		try container.encode(self.identity.authenticationUsername, forKey: .authenticationUsername)
		try container.encode(self.identity.authenticationPassword, forKey: .authenticationPassword)
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

extension User: BasicAuthenticatable {
	static let usernameKey: UsernameKey = \.authenticationUsername
	static let passwordKey: PasswordKey = \.authenticationPassword

	public static func authenticate(using basic: BasicAuthorization, verifier: PasswordVerifier, on conn: DatabaseConnectable) -> Future<User?> {
		do {
			return try User.query(on: conn).filter(usernameKey == basic.username).first().map(to: User?.self) { user in
				guard let user = user, try verifier.verify(basic.password, created: user.basicPassword) else {
					return nil
				}
				
				return user
			}
		} catch {
			return conn.eventLoop.newFailedFuture(error: error)
		}
	}
}

extension User: TokenAuthenticatable {
	typealias TokenType = Token
}

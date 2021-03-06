import FluentSQLite
import Vapor

extension User {
	enum CodingError: Error { case couldNotConvert }
	struct Identity: Codable, SQLiteDataConvertible, SQLiteFieldTypeStaticRepresentable {
		enum Kind: String { case email, twitter, facebook }
		enum CodableKey: CodingKey { case kind, email, password, serviceID, serviceName, serviceImageURL }
		
		var kind: Kind
		var password: String?			//just a hash
		var email: String?
		var serviceID: String?
		var serviceName: String?
		var serviceImageURL: String?
		
		var authenticationUsername: String { return self.email ?? self.derivedUsername }
		var authenticationPassword: String { return self.password ?? "password" }
		
		var isSuperuser: Bool {
			return self.email?.hasSuffix("@standalone.com") == true
		}
		
		var derivedUsername: String {
			if let email = self.email, !email.isEmpty { return email }
			var username = self.kind.rawValue + "-"
			if let serviceID = self.serviceID { username += serviceID }
			return username
		}
		
		static var sqliteFieldType: SQLiteFieldType { return .blob }
		static func convertFromSQLiteData(_ data: SQLiteData) throws -> Identity {
			if let raw = data.blob {
				return try JSONDecoder().decode(self, from: raw)
			}
			throw CodingError.couldNotConvert
		}
		
		func convertToSQLiteData() throws -> SQLiteData {
			let raw = try JSONEncoder().encode(self)
			return SQLiteData.blob(raw)
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKey.self)
			
			self.password = try container.decodeIfPresent(String.self, forKey: .password)
			self.email = try container.decodeIfPresent(String.self, forKey: .email)
			self.serviceID = try container.decodeIfPresent(String.self, forKey: .serviceID)
			self.serviceName = try container.decodeIfPresent(String.self, forKey: .serviceName)
			self.serviceImageURL = try container.decodeIfPresent(String.self, forKey: .serviceImageURL)
			if let kind = try container.decodeIfPresent(String.self, forKey: .kind) {
				self.kind = Kind(rawValue: kind) ?? .email
			} else {
				self.kind = .email
			}
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKey.self)
			
			try container.encode(self.password, forKey: .password)
			try container.encode(self.email, forKey: .email)
			try container.encode(self.serviceID, forKey: .serviceID)
			try container.encode(self.kind.rawValue, forKey: .kind)
			try container.encode(self.serviceName, forKey: .serviceName)
			try container.encode(self.serviceImageURL, forKey: .serviceImageURL)
		}
		
		init(email: String, password: String) {
			self.kind = .email
			self.password = password
			self.email = email
		}
		
		init?(twitterID: String?) {
			self.kind = .twitter
			self.serviceID = twitterID
			if self.serviceID == nil { return nil }
		}
		
		init?(facebookID: String?) {
			self.kind = .facebook
			self.serviceID = facebookID
			if self.serviceID == nil { return nil }
		}
	}
}

extension User.Identity {
	var `public`: Public {
		return Public(self)
	}
	
	struct Public: Codable {
		var kind: Kind
		var email: String?
		var serviceID: String?
		var serviceName: String?
		var serviceImageURL: String?

		init(_ identity: User.Identity) {
			self.kind = identity.kind
			self.email = identity.email
			self.serviceID = identity.serviceID
			self.serviceName = identity.serviceName
			self.serviceImageURL = identity.serviceImageURL
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodableKey.self)
			
			self.email = try container.decodeIfPresent(String.self, forKey: .email)
			self.serviceID = try container.decodeIfPresent(String.self, forKey: .serviceID)
			self.serviceName = try container.decodeIfPresent(String.self, forKey: .serviceName)
			self.serviceImageURL = try container.decodeIfPresent(String.self, forKey: .serviceImageURL)
			if let kind = try container.decodeIfPresent(String.self, forKey: .kind) {
				self.kind = Kind(rawValue: kind) ?? .email
			} else {
				self.kind = .email
			}
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKey.self)
			
			try container.encode(self.email, forKey: .email)
			try container.encode(self.serviceID, forKey: .serviceID)
			try container.encode(self.kind.rawValue, forKey: .kind)
			try container.encode(self.serviceName, forKey: .serviceName)
			try container.encode(self.serviceImageURL, forKey: .serviceImageURL)
		}
	}
}

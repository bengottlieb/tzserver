import FluentSQLite
import Vapor

extension User {
	enum CodingError: Error { case couldNotConvert }
	struct Identity: Codable, SQLiteDataConvertible, SQLiteFieldTypeStaticRepresentable {
		enum Kind: String { case email, twitter, facebook }
		enum CodableKey: CodingKey { case kind, email, password, serviceID }
		
		var kind: Kind
		var password: String?			//just a hash
		var email: String?
		var serviceID: String?
		
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
			if let kind = try container.decodeIfPresent(String.self, forKey: .kind) {
				self.kind = Kind(rawValue: kind) ?? .email
			} else {
				self.kind = .email
			}
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodableKey.self)
			
			if let password = self.password { try container.encode(password, forKey: .password) }
			if let email = self.email { try container.encode(email, forKey: .email) }
			if let serviceID = self.serviceID { try container.encode(serviceID, forKey: .serviceID) }
			try container.encode(self.kind.rawValue, forKey: .kind)
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

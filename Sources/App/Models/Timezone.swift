import FluentSQLite
import Vapor

/// A single entry of a User list.
final class Timezone: Codable {
	var id: Int?
	var name: String
	var officialName: String
	var abbreviation: String
	var placeID: String?
	var cityName: String?

	var ownerID: Int?

	init(name: String, officialName: String, abbreviation: String, nearbyCity: String, placeID: String?) {
		self.name = name
		self.officialName = officialName
		self.abbreviation = abbreviation
		self.cityName = nearbyCity
		self.placeID = placeID
	}
}

extension Timezone: SQLiteModel {
	var owner: Parent<Timezone, User>? {
		return parent(\.ownerID)
	}
}


/// Allows `Timezone` to be used as a dynamic migration.
extension Timezone: Migration { }

/// Allows `Timezone` to be encoded to and decoded from HTTP messages.
extension Timezone: Content { }

/// Allows `Timezone` to be used as a dynamic parameter in route definitions.
extension Timezone: Parameter { }

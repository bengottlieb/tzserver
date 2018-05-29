//
//  TimezoneController.swift
//  App
//
//  Created by Ben Gottlieb on 5/27/18.
//

import Vapor
import Fluent

struct TimezonesController: RouteCollection {
	func boot(router: Router) throws {
		let timezonesRoute = router.grouped("api", "timezones")
		timezonesRoute.get(use: getAllHandler)
		timezonesRoute.get(Timezone.parameter, use: getHandler)
		timezonesRoute.get(Timezone.parameter, "owner", use: getOwnerHandler)
	//	timezonesRoute.get("search", use: searchHandler)
		
		let tokenAuthMiddleware = User.tokenAuthMiddleware()
		let tokenAuthGroup = timezonesRoute.grouped(tokenAuthMiddleware)
		tokenAuthGroup.post(use: createHandler)
		tokenAuthGroup.delete(Timezone.parameter, use: deleteHandler)
		tokenAuthGroup.put(Timezone.parameter, use: updateHandler)
	}
	
	func getAllHandler(_ req: Request) throws -> Future<[Timezone]> {
		return Timezone.query(on: req).all()
	}
	
	func createHandler(_ req: Request) throws -> Future<Timezone> {
		return try req.content.decode(Timezone.self).flatMap(to: Timezone.self) { timezone in
			let user = try req.requireAuthenticated(User.self)
//			let timezone = try Timezone(short: timezoneData.short, long: timezoneData.long, ownerID: user.requireID())
			timezone.ownerID = user.id
			return timezone.save(on: req)
		}
	}
	
	func getHandler(_ req: Request) throws -> Future<Timezone> {
		return try req.parameters.next(Timezone.self)
	}
	
	func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
		return try req.parameters.next(Timezone.self).flatMap(to: HTTPStatus.self) { timezone in
			return timezone.delete(on: req).transform(to: .noContent)
		}
	}
	
	func updateHandler(_ req: Request) throws -> Future<Timezone> {
		return try flatMap(to: Timezone.self, req.parameters.next(Timezone.self), req.content.decode(Timezone.self)) { timezone, updatedTimezone in
			timezone.abbreviation = updatedTimezone.abbreviation
			timezone.cityName = updatedTimezone.cityName
			timezone.name = updatedTimezone.name
			timezone.gmtOffset = updatedTimezone.gmtOffset
			timezone.dstOffset = updatedTimezone.dstOffset
			timezone.identifierName = updatedTimezone.identifierName

			timezone.ownerID = try req.requireAuthenticated(User.self).requireID()
			return timezone.save(on: req)
		}
	}
	
	func getOwnerHandler(_ req: Request) throws -> Future<User> {
		return try req.parameters.next(Timezone.self).flatMap(to: User.self) { timezone in
			return try timezone.owner!.get(on: req)
		}
	}
	
//	func searchHandler(_ req: Request) throws -> Future<[Timezone]> {
//		guard let searchTerm = req.query[String.self, at: "term"] else {
//			throw Abort(.badRequest, reason: "Missing search term in request")
//		}
//		return Timezone.query(on: req).group(.or) { or in
//			or.filter(\.short == searchTerm)
//			or.filter(\.long == searchTerm)
//			}.all()
//	}
}

struct TimezoneCreateData: Content {
	let short: String
	let long: String
}

//
//  UserController+Setup.swift
//  App
//
//  Created by Ben Gottlieb on 5/26/18.
//

import Vapor
import Crypto
import Authentication


extension UsersController {
	func existsHandler(_ req: Request) throws -> Future<ExistsPayload> {
		let checkName = try req.parameters.next(String.self)
		return req.withPooledConnection(to: .sqlite) { conn in
			do {
				return try User.query(on: conn).filter(\.authenticationUsername == checkName).first().map(to: ExistsPayload.self) { user in
					return ExistsPayload(user: user)
				}
			} catch {
				return conn.eventLoop.newFailedFuture(error: error)
			}
		}
	}
	
	func validationHandler(_ req: Request) throws -> Future<User> {
		let checkToken = try req.parameters.next(String.self)
		return req.withPooledConnection(to: .sqlite) { conn in
			do {
				return try User.query(on: conn).filter(\User.verificationToken == checkToken).first().map(to: User.self) { user in
					return user!
				}
			} catch {
				return conn.eventLoop.newFailedFuture(error: error)
			}
		}
	}
	
//	func validationHandler(_ req: Request) throws -> String {
//		let checkToken = try req.parameters.next(String.self)
//		req.withPooledConnection(to: .sqlite) { conn in
//			do {
//				try User.query(on: conn).filter(\.verificationToken == checkToken).first().map(to: User.self) { user in
//					user.emailIsVerified = true
//					user.save(on: req)
//				}
//			} catch { }
//		}
//
//		return "Thanks!"
//	}
}

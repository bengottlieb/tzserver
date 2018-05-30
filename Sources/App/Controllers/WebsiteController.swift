//
//  WebsiteController.swift
//  App
//
//  Created by Ben Gottlieb on 5/26/18.
//

import Vapor
import Leaf
import Crypto
import Authentication

struct WebsiteController: RouteCollection {
	func boot(router: Router) throws {
		router.get(use: indexHandler)
		router.get("verify", String.parameter, use: handleVerification)
		router.get("rsvp", String.parameter, use: handleRSVP)
		router.post("rsvp-set-password", use: handlePasswordSet)
	}
	
	func indexHandler(_ req: Request) throws -> Future<View> {
		return try req.view().render("index")
	}
	
	func handlePasswordSet(_ req: Request) throws -> Future<View> {
		struct Input: Codable {
			let email: String
			let password: String
		}
		
		return try req.content.decode(Input.self).flatMap(to: View.self) { input in
			_ = req.withPooledConnection(to: .sqlite) { conn in
				try User.query(on: conn).filter(\User.authenticationUsername == input.email).first().map(to: User.self) { found in
					let hasher = try req.make(BCryptDigest.self)
					let hashed = try hasher.hash(input.password, salt: "$2b$12$55hXn3a3wV5Ek3O6ZT2TUe")

					guard let user = found else {
						throw Abort(.proxyAuthenticationRequired, reason: "No user with this email found. Please re-check your email and click the activation link.")
					}

					if user.authenticationPassword != "" {
						throw Abort(.conflict, reason: "This user has already configured their account.")
					}
					
					user.identity.password = hashed
					user.authenticationPassword = hashed

					_ = user.save(on: req)
					return user
				}
			}
			return try req.view().render("password-set")
		}
	}
	
	func handleRSVP(_ req: Request) throws -> Future<View> {
		struct Payload: Codable {
			let email: String
		}
		
		let email = try req.parameters.next(String.self)
		let payload = Payload(email: email)
		
		return try req.view().render("rsvpd", payload)

	}
	
	func handleVerification(_ req: Request) throws -> Future<View> {
		let checkToken = try req.parameters.next(String.self)
//		return req.withPooledConnection(to: .sqlite) { conn in
//			do {
//				return try User.query(on: conn).filter(\User.verificationToken == checkToken).first().map(to: User.self) { user in
//					//return user!
//					return try req.view().render("verified")
//				}
//			} catch {
//				return conn.eventLoop.newFailedFuture(error: error)
//			}
//		}

		//		let checkToken = try req.parameters.next(String.self)

		_ = req.withPooledConnection(to: .sqlite) { conn in
			try User.query(on: conn).filter(\User.verificationToken == checkToken).first().map(to: User.self) { user in
				guard let user = user else {
					throw Abort(.proxyAuthenticationRequired, reason: "No token found. Please re-check your email and click the activation link.")
				}
				user.emailIsVerified = true
				_ = user.save(on: req)
				return user
			}
		}
		return try req.view().render("verified")
	}
}


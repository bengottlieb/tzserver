import Vapor
import Crypto
import Authentication

struct LoginResult: Codable, Content {
	let user: User.Public
	let token: String
}

/// Controls basic CRUD operations on `User`s.
struct UsersController: RouteCollection {
	func boot(router: Router) throws {
		let usersRoute = router.grouped("api", "users")
		
		usersRoute.get("exists", String.parameter, use: existsHandler)
		usersRoute.get("validate", String.parameter, use: validationHandler)

//		usersRoute.get(use: getAllHandler)
//		usersRoute.put(User.parameter, use: updateHandler)
		usersRoute.post(use: createHandler)
//		usersRoute.get(User.Public.parameter, use: getHandler)
//		usersRoute.delete(User.parameter, use: deleteHandler)
//		usersRoute.get(User.parameter, "timezones", use: getTimezonesHandler)
		
		let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
		let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
		basicAuthGroup.post("login", use: loginHandler)
		
		let tokenAuthMiddleware = User.tokenAuthMiddleware()
		let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware)
		tokenAuthGroup.delete(User.parameter, use: deleteHandler)
		tokenAuthGroup.get(User.parameter, use: getHandler)
		tokenAuthGroup.get(User.parameter, "timezones", use: getTimezonesHandler)
		tokenAuthGroup.get(use: getAllHandler)
		tokenAuthGroup.put(User.parameter, use: updateHandler)
	}
		
	func getAllHandler(_ req: Request) throws -> Future<[User]> {
		_ = try req.requireAuthenticated(User.self)
		return User.query(on: req).all()
	}
	
	func getTimezonesHandler(_ req: Request) throws -> Future<[Timezone]> {
		_ = try req.requireAuthenticated(User.self)

		return try req.parameters.next(User.self).flatMap(to: [Timezone].self) { user in
			return try user.timezones.query(on: req).all()
		}
	}
	
	func loginHandler(_ req: Request) throws -> Future<Response> {
		let user = try req.requireAuthenticated(User.self)
		if user.emailIsVerified == false {
			throw Abort(.badRequest, reason: "\(user.name ?? "user") has not been verified.")
		}

		let token = try Token.generate(for: user)
		_ = token.save(on: req)
		return try LoginResult(user: user.public, token: token.token).encode(for: req)
	}
	
	func createHandler(_ req: Request) throws -> Future<LoginResult> {
		return try req.content.decode(User.self).flatMap(to: LoginResult.self) { incoming in
			
			return req.withPooledConnection(to: .sqlite) { conn in
				do {
					return try User.query(on: conn).filter(\User.authenticationUsername == incoming.authenticationUsername).first().map(to: LoginResult.self) { user in
						if user != nil {
							throw Abort(.badRequest, reason: "User already exists")
						}
						
						let hasher = try req.make(BCryptDigest.self)
						incoming.identity.password = try hasher.hash(incoming.identity.password ?? "password")
						
						if incoming.identity.kind == .email {
							let random = try CryptoRandom().generateData(count: 16)
							incoming.verificationToken = random.base64EncodedString()
							
							incoming.sendVerificationEmail()
						} else {
							incoming.emailIsVerified = true
						}
						
						print("Created user: \(incoming)")
						_ = incoming.save(on: req)

						let token = try Token.generate(for: incoming)
						_ = token.save(on: req)
						return LoginResult(user: incoming.public, token: token.token)
					}
				} catch {
					return conn.eventLoop.newFailedFuture(error: error)
				}
			}
		}
	}
	
	func getHandler(_ req: Request) throws -> Future<User> {
		let currentUser = try req.requireAuthenticated(User.self)
		
		return try req.parameters.next(User.self).flatMap(to: User.self) { user in
			if currentUser.permissions != .admin && user.id != currentUser.id {
				throw Abort(.badRequest, reason: "\(currentUser.name ?? "user") is not an admin.")
			}
			return user.save(on: req)
		}
	}
	
	func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
		let user = try req.requireAuthenticated(User.self)
		if user.permissions != .admin {
			throw Abort(.badRequest, reason: "\(user.name ?? "user") is not an admin.")
		}
		return try req.parameters.next(User.self).flatMap(to: HTTPStatus.self) { user in
			return user.delete(on: req).transform(to: .noContent)
		}
	}
	
	func updateHandler(_ req: Request) throws -> Future<User> {
		let currentUser = try req.requireAuthenticated(User.self)
		if currentUser.permissions != .admin {
			throw Abort(.badRequest, reason: "\(currentUser.name ?? "user") is not an admin.")
		}

		return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) { user, updated in
			let current = try req.requireAuthenticated(User.self)
			if current.permissions != .admin && current.id != user.id {
				throw Abort(.badRequest, reason: "\(user.name ?? "user") is not an admin.")
			}

			user.permissions = updated.permissions
			user.name = updated.name
			user.identity = updated.identity
			return user.save(on: req)
		}
	}
	
//	func getTimezonesHandler(_ req: Request) throws -> Future<[Timezone]> {
//		return try req.parameters.next(User.self).flatMap(to: [Timezone].self) { user in
//			return try user.timezones.query(on: req).all()
//		}
//	}
}

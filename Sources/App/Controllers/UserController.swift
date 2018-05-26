import Vapor
import Crypto

/// Controls basic CRUD operations on `User`s.
struct UsersController: RouteCollection {
	func boot(router: Router) throws {
		let usersRoute = router.grouped("api", "users")
		
		usersRoute.get(use: getAllHandler)
		usersRoute.put(User.parameter, use: updateHandler)
		usersRoute.post(use: createHandler)
		usersRoute.get(User.parameter, use: getHandler)
		usersRoute.delete(User.parameter, use: deleteHandler)
//		usersRoute.get(User.parameter, "timezones", use: getTimezonesHandler)
	}
	
	func getAllHandler(_ req: Request) throws -> Future<[User]> {
		return User.query(on: req).all()
	}
	
	func createHandler(_ req: Request) throws -> Future<User> {
		return try req.content.decode(User.self).flatMap(to: User.self) { user in
			let hasher = try req.make(BCryptDigest.self)
			user.identity.password = user.identity.password != nil ? try hasher.hash(user.identity.password!) : nil
			return user.save(on: req)
		}
	}
	
	func getHandler(_ req: Request) throws -> Future<User> {
		return try req.parameters.next(User.self)
	}
	
	func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
		return try req.parameters.next(User.self).flatMap(to: HTTPStatus.self) { user in
			return user.delete(on: req).transform(to: .noContent)
		}
	}
	
	func updateHandler(_ req: Request) throws -> Future<User> {
		return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) { user, updated in
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

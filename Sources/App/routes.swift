import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

	try router.register(collection: UsersController())
	try router.register(collection: TimezonesController())
	try router.register(collection: WebsiteController())
}

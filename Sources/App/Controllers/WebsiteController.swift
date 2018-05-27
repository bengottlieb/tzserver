//
//  WebsiteController.swift
//  App
//
//  Created by Ben Gottlieb on 5/26/18.
//

import Vapor
import Leaf

struct WebsiteController: RouteCollection {
	func boot(router: Router) throws {
		router.get(use: indexHandler)
	}
	
	func indexHandler(_ req: Request) throws -> Future<View> {
		return try req.view().render("index") 	}
}


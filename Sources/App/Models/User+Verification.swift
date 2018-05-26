//
//  User+Verification.swift
//  App
//
//  Created by Ben Gottlieb on 5/26/18.
//

import Foundation

// sample: https://api.mailgun.net/v3/mg.bengottlieb.com/messages?from=Ben<ben@ben.com>&to=ben@standalone.com&subject="Hello"&text="Test contents"

extension User {
	func sendVerificationEmail() {
		guard let toAddress = self.identity.email, let validationToken = self.verificationToken else { return }
		let credentials = "api:key-9aa909efe57d51eb4da88147fd35217e"

		let fromAddress = "info@timezones.com".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let subject = "Welcome to Timezones!".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//		let link = "https://timezones-develop.vapor.cloud/api/users/validate/\(validationToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let link = "http://localhost:8080/api/users/validate/\(validationToken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		let body = "Thanks for signing up to Timezones! Please validate your account by following this link: \(link).\n\nThanks, the Timezones Team!".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		var baseURL = "https://api.mailgun.net/v3/mg.bengottlieb.com/messages?"
		
		baseURL += "&to=\(toAddress)"
		baseURL += "&from=\(fromAddress)"
		baseURL += "&subject=\(subject)"
		baseURL += "&text=\(body)"

		print("Sending verification email to: \(baseURL)")
		var request = URLRequest(url: URL(string: baseURL)!)
		request.httpMethod = "POST"
		request.setValue("Basic \(credentials.toBase64())", forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			if let error = error {
				print("Error while sending verification email: \(error)")
			} else if let data = data, let result = String(data: data, encoding: .utf8) {
				print("Result from sending verification email: \(result)")
			}
		}
		
		task.resume()
	}
}

extension String {
	
	func fromBase64() -> String? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		
		return String(data: data, encoding: .utf8)
	}
	
	func toBase64() -> String {
		return Data(self.utf8).base64EncodedString()
	}
}

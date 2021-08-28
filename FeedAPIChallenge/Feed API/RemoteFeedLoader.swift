//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			// to prevent memory leak
			guard self != nil else { return }

			switch result {
			case let .success((data, response)):
				guard response.statusCode == 200 else {
					return completion(.failure(Error.invalidData))
				}

				// decode process
				if let root = try? JSONDecoder().decode(Root.self, from: data) {
					completion(.success(root.feedImages))
				} else {
					return completion(.failure(Error.invalidData))
				}

			default:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private struct Root: Decodable {
		var items: [Image]

		var feedImages: [FeedImage] {
			return items.map { $0.feedImage }
		}
	}

	private struct Image: Decodable {
		let id: UUID
		let imageDesc: String?
		let imageLoc: String?
		let imageURL: URL

		enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case imageDesc = "image_desc"
			case imageLoc = "image_loc"
			case imageURL = "image_url"
		}

		var feedImage: FeedImage {
			return FeedImage(id: id, description: imageDesc, location: imageLoc, url: imageURL)
		}
	}
}

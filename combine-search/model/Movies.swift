//
//  Movies.swift
//  combine-search
//
//  Created by Kelvin Fok on 23/3/23.
//

import Foundation

struct MoviesResponse: Decodable, Hashable {
  let result: [Movie]
  
  enum CodingKeys: String, CodingKey {
    case result = "Search"
  }
}

struct Movie: Decodable, Hashable, Identifiable {

  let title: String
  let year: String
  let poster: String
  let id = UUID()
  
  enum CodingKeys: String, CodingKey {
    case title = "Title"
    case year = "Year"
    case poster = "Poster"
  }
}

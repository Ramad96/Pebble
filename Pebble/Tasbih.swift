//
//  Tasbih.swift
//  Pebble
//

import Foundation

struct DhikrStep: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var target: Int
}

struct Tasbih: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var steps: [DhikrStep]
}

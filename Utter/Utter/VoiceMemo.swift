//
//  VoiceMemo.swift
//  Utter
//
//  Created by Ritika Joshi on 3/15/26.
//

import Foundation

struct VoiceMemo: Identifiable, Codable {
    let id: UUID
    var text: String
    var category: String
    var date: Date
    var isDone: Bool

    init(id: UUID = UUID(), text: String, category: String, date: Date, isDone: Bool = false) {
        self.id = id
        self.text = text
        self.category = category
        self.date = date
        self.isDone = isDone
    }
}

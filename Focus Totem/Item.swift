//
//  Item.swift
//  Focus Totem
//
//  Created by Daniele Spaccapeli on 18/03/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

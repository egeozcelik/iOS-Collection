//
//  Message.swift
//  MeetNow
//
//  Created by Ege Özçelik on 15.08.2025.
//

import SwiftUI

struct Message: Identifiable {
    let id: String
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: Date
}

//
//  Conversation.swift
//  MeetNow
//
//  Created by Ege Özçelik on 15.08.2025.
//

import SwiftUI

struct Conversation: Identifiable {
    let id: String
    let otherUser: User
    let eventTitle: String
    let lastMessage: String
    let lastMessageTime: String
}

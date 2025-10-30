//
//  User.swift
//  MeetNow
//
//  Created by Ege Özçelik on 15.08.2025.
//

import SwiftUI

struct User {
    let id: String
    let name: String
    let phoneNumber: String
    let profileImageURL: String
    let age: Int
    
    static let mockUser = User(
        id: "1",
        name: "Sarah Johnson",
        phoneNumber: "+1234567890",
        profileImageURL: "https://picsum.photos/200/200",
        age: 25
    )
}

//
//  Constants.swift
//  MeetNow
//
//  Created by Ege Özçelik on 15.08.2025.
//

import SwiftUI

enum EventIcon: String, CaseIterable {
    case coffee = "cup.and.saucer.fill"
    case food = "fork.knife"
    case movie = "tv.fill"
    case sports = "figure.run"
    case music = "music.note"
    case drinks = "wineglass.fill"
    case study = "book.fill"
    case gaming = "gamecontroller.fill"
    case shopping = "bag.fill"
    case outdoor = "tree.fill"
    case fitness = "dumbbell.fill"
    case art = "paintbrush.fill"
    
    var systemName: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .coffee: return "Coffee"
        case .food: return "Food"
        case .movie: return "Movie"
        case .sports: return "Sports"
        case .music: return "Music"
        case .drinks: return "Drinks"
        case .study: return "Study"
        case .gaming: return "Gaming"
        case .shopping: return "Shopping"
        case .outdoor: return "Outdoor"
        case .fitness: return "Fitness"
        case .art: return "Art"
        }
    }
}

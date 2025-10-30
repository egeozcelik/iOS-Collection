//
//  Game.swift
//  AppStore[Clone]
//
//  Created by Ege Özçelik on 30.09.2023.
//

import Foundation


class Game{
    var game_id:Int?
    var name:String?
    var description:String?
    var picture:String?
    
    init(game_id: Int, name: String, description: String, picture: String) {
        self.game_id = game_id
        self.name = name
        self.description = description
        self.picture = picture
    }
}

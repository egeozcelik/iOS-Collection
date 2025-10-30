//
//  Banner.swift
//  NotyApp
//
//  Created by Ege Özçelik on 12.12.2023.
//

import Foundation

class Banner{
    var id:String?
    var mainLabel:String?
    var subLabel:String?
        
    init(id: String?, mainLabel: String, subLabel: String) {
        self.id = id
        self.mainLabel = mainLabel
        self.subLabel = subLabel
    }
}

//
//  NotyKayitViewModel.swift
//  NotyApp
//
//  Created by Ege Özçelik on 2.12.2023.
//

import Foundation


class NotyKayitViewModel{

    var mainRepo = MainRepository()
    
    
    func addNoty(newNoty:Noty){
        mainRepo.addNoty(newNoty: newNoty)
    }
}

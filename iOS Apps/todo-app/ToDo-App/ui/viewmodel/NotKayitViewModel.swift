//
//  NotKayitViewModel.swift
//  ToDo-App
//
//  Created by Ege Özçelik on 3.10.2023.
//

import Foundation


class NotKayitViewModel{
    
    var tdRepo = NotRepository()
    
    func kaydet(todo:String){
        tdRepo.kaydet(todo: todo)
    }
    
    
}

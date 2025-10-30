//
//  NotDetayViewModel.swift
//  ToDo-App
//
//  Created by Ege Özçelik on 3.10.2023.
//

import Foundation


class NotDetayViewModel{
    var tdRepo = NotRepository()
    
    func guncelle(todo_id:Int, todo:String){
        tdRepo.guncelle(td_id: todo_id, todo: todo)
    }
    
}

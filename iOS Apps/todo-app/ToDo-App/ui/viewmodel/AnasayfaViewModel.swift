//
//  AnasayfaViewModel.swift
//  ToDo-App
//
//  Created by Ege Özçelik on 3.10.2023.
//

import Foundation
import RxSwift

class AnasayfaViewModel{
    var tdRepo = NotRepository()
    
    var todoListesi = BehaviorSubject<[ToDos]>(value: [ToDos]())
    
    init() {
        tdRepo.veritabaniKopyala()
        self.todoListesi = tdRepo.todoListesi
    }
    
    func ara(aramaKelimesi:String){
        tdRepo.ara(aramaKelimesi: aramaKelimesi)
    }
    
    func sil(todo_id:Int){
        tdRepo.sil(todo_id: todo_id)
        todoYukle()
    }
    
    func todoYukle(){
        tdRepo.todoYukle()
    }
}

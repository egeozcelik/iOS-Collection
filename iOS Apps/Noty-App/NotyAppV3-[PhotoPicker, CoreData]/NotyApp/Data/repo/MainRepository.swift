//
//  MainRepo.swift
//  NotyApp
//
//  Created by Ege Özçelik on 2.12.2023.
//

import Foundation
import RxSwift
import CoreData


class MainRepository{
    
    var notyList = BehaviorSubject<[NotyModel]>(value: [NotyModel]())
   
    let context = appDelegate.persistentContainer.viewContext
    
    init(){
        
    }
    
    func addNoty(newNoty:Noty){
        let savedNoty = NotyModel(context: context)
        savedNoty.ders = newNoty.ders
        savedNoty.fiyat =  Int32(newNoty.fiyat!)
        savedNoty.indirme = 150 // Int32(newNoty.indirme!)
        savedNoty.konu = newNoty.konu
        savedNoty.resim = "img2" //newNoty.resim
        savedNoty.sayfaAdet = 10 //Int32(newNoty.sayfaAdet!)
        savedNoty.yazar = "ege ozcelik" //newNoty.yazar
        
        appDelegate.saveContext()
        
    }
    
    func searchNoty(keyword:String){
        do {
            let fr = NotyModel.fetchRequest()
            fr.predicate = NSPredicate(format: "konu CONTAINS[c] %@", keyword)
            let list = try context.fetch(fr)
            notyList.onNext(list)
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func deleteNoty(noty:NotyModel){
        context.delete(noty)
        appDelegate.saveContext()
    }
    
    
    func updateNoty(noty:Noty, notyModel:NotyModel){
        
        notyModel.ders = noty.ders
        notyModel.fiyat =  Int32(noty.fiyat!)
        notyModel.indirme = 150 // Int32(newNoty.indirme!)
        notyModel.konu = noty.konu
        notyModel.resim = "img2" //newNoty.resim
        notyModel.sayfaAdet = 10 //Int32(newNoty.sayfaAdet!)
        notyModel.yazar = "ege ozcelik" //newNoty.yazar
        
        appDelegate.saveContext()
    }
    
    func getNotyList(){
        
        do {
            let list = try context.fetch(NotyModel.fetchRequest())
            notyList.onNext(list)
        }catch{
            print(error.localizedDescription)
        }
        
       
    }
    
    
    
    
    func getNotyList_old(){
        var list = [Noty]()
        let n1 = Noty(id: 1, ders: "physics", konu: "Kuantum Mekaniği", resim: "img1", sayfaAdet: 7, yazar: "okandurur", indirme: 192, fiyat: 10)
        let n2 = Noty(id: 2, ders: "chemistry", konu: "Asitler ve Bazlar", resim: "img2", sayfaAdet: 5, yazar: "okandurur", indirme: 250, fiyat: 10)
        let n3 = Noty(id: 3, ders: "physics", konu: "Doppler Olayı", resim: "img3", sayfaAdet: 3, yazar: "egeozcelik", indirme: 1002, fiyat: 10)
        let n4 = Noty(id: 4, ders: "mathematics", konu: "Türev Alma Kuralları", resim: "img4", sayfaAdet: 5, yazar: "okandurur", indirme: 802, fiyat: 50)
        let n5 = Noty(id: 5, ders: "science", konu: "Norton ve Thevenin Devreleri", resim: "img5", sayfaAdet: 4, yazar: "egeozcelik", indirme: 150, fiyat: 50)
        let n6 = Noty(id: 6, ders: "science", konu: "Türlerin Kökeni", resim: "img6", sayfaAdet: 3, yazar: "okandurur", indirme: 50, fiyat: 50)
        let n7 = Noty(id: 7, ders: "languageArts", konu: "Organik Kimyaya Giriş(1)", resim: "img7", sayfaAdet: 11, yazar: "okandurur", indirme: 12, fiyat: 20)
        
        
        list.append(n1)
        list.append(n2)
        list.append(n3)
        list.append(n4)
        list.append(n5)
        list.append(n6)
        list.append(n7)
    }
}

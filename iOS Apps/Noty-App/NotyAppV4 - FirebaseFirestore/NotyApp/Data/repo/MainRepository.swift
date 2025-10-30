//
//  MainRepo.swift
//  NotyApp
//
//  Created by Ege Özçelik on 2.12.2023.
//

import Foundation
import RxSwift
//import CoreData
import FirebaseFirestore


// Noty Class

//var id:String?
//var ders:String?
//var konu:String?
//var resim:String?
//var sayfaAdet:String?
//var yazar: String?
//var indirme:String?
//var fiyat:String?


class MainRepository{
    
        var notyList = BehaviorSubject<[Noty]>(value: [Noty]())
        var collectionNoty = Firestore.firestore().collection("Noty")
    
    
        let context = appDelegate.persistentContainer.viewContext
    
        init(){
        
        }
    
        func getNotyList(){
        
            let query = collectionNoty.order(by: "fiyat", descending: true) // Fiyata göre küçükten büyüğe: ASC
        
            query.addSnapshotListener { snapshot, error in
                var list = [Noty]()
        
                if let documents = snapshot?.documents{
                    print("document count noties:\(documents.count)")
                    for document in documents {
                        
                        let data = document.data()
                        //document => bütün satır(DocumentID dahil)
                        let id = document.documentID
                        //data => benim girdiğim veriler(DocumentID harici)
                        let ders = data["ders"] as? String ?? ""
                        let konu = data["konu"] as? String ?? ""
                        let icerik = data["icerik"] as? String ?? ""
                        let resim = data["resim"] as? String ?? ""
                        let sayfaAdet = data["sayfaAdet"] as? String ?? ""
                        let yazar = data["yazar"] as? String ?? ""
                        let indirme = data["indirme"] as? String ?? ""
                        let fiyat = data["fiyat"] as? String ?? ""
            
                      
                        let noty = Noty(id: id, ders: ders, konu: konu, icerik: icerik, resim: resim, sayfaAdet: sayfaAdet, yazar: yazar, indirme: indirme, fiyat: fiyat)
                    
                    
                        list.append(noty)
                    }
                    print("noty list items: \(list.count)")
                }
            
                self.notyList.onNext(list)
            }
        
        }
    
        func addNoty(newNoty:Noty){
            if let ders = newNoty.ders, let konu = newNoty.konu, let icerik = newNoty.icerik, let resim = newNoty.resim, let sayfaAdet = newNoty.sayfaAdet, let yazar = newNoty.yazar, let indirme = newNoty.indirme, let fiyat = newNoty.fiyat{
           
                let addedNoty:[String:Any] = ["id":" ", "ders":ders, "konu":konu, "icerik": icerik, "resim":resim, "sayfaAdet":sayfaAdet, "yazar":yazar, "indirme":indirme, "fiyat":fiyat]
           
                collectionNoty.document().setData(addedNoty)
            }
        }
    
        func searchNoty(keyword:String){
            
            collectionNoty.addSnapshotListener { snapshot, error in
            
                var list = [Noty]()
        
                if let documents = snapshot?.documents{
                    for document in documents {
                        let data = document.data()
                        //document => bütün satır(DocumentID dahil)
                        let id = document.documentID
                        //data => benim girdiğim veriler(DocumentID harici)
                        let ders = data["ders"] as? String ?? ""
                        let konu = data["konu"] as? String ?? ""
                        let icerik = data["icerik"] as? String ?? ""
                        let resim = data["resim"] as? String ?? ""
                        let sayfaAdet = data["sayfaAdet"] as? String ?? ""
                        let yazar = data["yazar"] as? String ?? ""
                        let indirme = data["indirme"] as? String ?? ""
                        let fiyat = data["fiyat"] as? String ?? ""
            
                        
                        if konu.lowercased().contains(keyword.lowercased()){
                            let noty = Noty(id: id, ders: ders, konu: konu, icerik: icerik, resim: resim, sayfaAdet: sayfaAdet, yazar: yazar, indirme: indirme, fiyat: fiyat)
                            list.append(noty)
                        }
                    }
                }
            
                self.notyList.onNext(list)
            }
            
        }
    
        func deleteNoty(noty:Noty){
            if let id = noty.id{
                collectionNoty.document(id).delete()
            }
        }
    
    
        func updateNoty(noty:Noty){
            if let id = noty.id, let ders = noty.ders, let konu = noty.konu, let icerik = noty.icerik, let resim = noty.resim, let sayfaAdet = noty.sayfaAdet, let yazar = noty.yazar, let indirme = noty.indirme, let fiyat = noty.fiyat{
                    let updatedNoty:[String:Any] = ["ders":ders, "konu":konu, "icerik": icerik, "resim":resim, "sayfaAdet":sayfaAdet, "yazar":yazar, "indirme":indirme, "fiyat":fiyat]
                    collectionNoty.document(id).updateData(updatedNoty)
            }
        }
    }

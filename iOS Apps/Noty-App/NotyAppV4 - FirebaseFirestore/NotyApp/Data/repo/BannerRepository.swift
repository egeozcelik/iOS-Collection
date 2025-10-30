//
//  BannerRepository.swift
//  NotyApp
//
//  Created by Ege Özçelik on 12.12.2023.
//

import Foundation
import RxSwift
import FirebaseFirestore


//var id:String?
//var mainLabel:String?
//var subLabel:String?

class BannerRepository{
    
    var bannerList = BehaviorSubject<[Banner]>(value: [Banner]())
    var collectionBanner = Firestore.firestore().collection("Banner")
    
    init(){
       // let addedBanner1:[String:Any] = ["id":"", "mainLabel": "Welcome to Noty", "subLabel":"Here are the best picks for you!"]
       // collectionBanner.document().setData(addedBanner1)
    }
    
    
    func getBanners(){
        collectionBanner.addSnapshotListener{ snapshot, error in
            var list = [Banner]()
            
            if let documents = snapshot?.documents{
                print("document count banners:\(documents.count)")
                for document in documents{
                    
                    let data = document.data()
                    
                    let id = document.documentID
                    
                    let mainLabel = data["mainLabel"] as? String ?? ""
                    let subLabel = data["subLabel"] as? String ?? ""
                    
                    let banner = Banner(id: id, mainLabel: mainLabel, subLabel: subLabel)
                    
                    list.append(banner)
                }
            }
            self.bannerList.onNext(list)
            
        }
    }
    
    
   
}

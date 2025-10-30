//
//  BasketPageViewModel.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import Foundation
import RxSwift
class BasketPageViewModel{
    
    var repo = Repository()
    var basketItemsList = BehaviorSubject<[sepet_yemekler]>(value: [sepet_yemekler]())
    
    init(){
        basketItemsList = repo.BasketItemsList
    }
    
    func GetBasketItems(kullaniciAdi:String){
        repo.GetBasketItems(kullaniciAdi: kullaniciAdi)
    }
    
    func DeleteItem(sepet_yemek_id:Int, kullanici_adi:String){
            repo.DeleteItem(sepet_yemek_id: sepet_yemek_id, kullanici_adi: kullanici_adi)
        
    }
    
}

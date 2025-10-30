//
//  ItemDetailsViewModel.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import Foundation

class ItemDetailsViewModel{
    var repo = Repository()
    
    func AddToBasket(yemek_adi:String, yemek_resim_adi:String, yemek_fiyat:Int, yemek_siparis_adet:Int, kullanici_adi:String){
        repo.AddToBasket(yemek_adi: yemek_adi, yemek_resim_adi: yemek_resim_adi, yemek_fiyat: yemek_fiyat, yemek_siparis_adet: yemek_siparis_adet, kullanici_adi: kullanici_adi)
    }
    
    func GetAllItems(){
        repo.GetAllItems()
    }
}

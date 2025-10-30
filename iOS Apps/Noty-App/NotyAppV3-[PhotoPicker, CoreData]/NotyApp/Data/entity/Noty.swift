//
//  Noty.swift
//  NotyApp
//
//  Created by Ege Özçelik on 28.11.2023.
//

import Foundation


class Noty{
    var id:Int?
    var ders:String?
    var konu:String?
    var resim:String?
    var sayfaAdet:Int?
    var yazar: String?
    var indirme:Int?
    var fiyat:Int?
    
    
    
    init(id: Int, ders: String, konu: String, resim: String, sayfaAdet: Int, yazar: String, indirme: Int, fiyat: Int) {
        self.id = id
        self.ders = ders
        self.konu = konu
        self.resim = resim
        self.sayfaAdet = sayfaAdet
        self.yazar = yazar
        self.indirme = indirme
        self.fiyat = fiyat
    }
}

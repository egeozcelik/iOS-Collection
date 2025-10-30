//
//  Noty.swift
//  NotyApp
//
//  Created by Ege Özçelik on 28.11.2023.
//

import Foundation


class Noty{
    var id:String?
    var ders:String?
    var konu:String?
    var icerik:String?
    var resim:String?
    var sayfaAdet:String?
    var yazar: String?
    var indirme:String?
    var fiyat:String?
    
    
    
    init(id: String, ders: String, konu: String, icerik:String, resim: String, sayfaAdet: String, yazar: String, indirme: String, fiyat: String) {
        self.id = id
        self.ders = ders
        self.konu = konu
        self.icerik = icerik
        self.resim = resim
        self.sayfaAdet = sayfaAdet
        self.yazar = yazar
        self.indirme = indirme
        self.fiyat = fiyat
    }
}

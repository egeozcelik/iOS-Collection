//
//  AnasayfaViewModel.swift
//  KisilerUygulamasi
//
//  Created by Kasım on 26.09.2023.
//

import Foundation
import RxSwift

class AnasayfaViewModel {
    var krepo = KisilerDaoRepository()
    var kisilerListesi = BehaviorSubject<[KisilerModel]>(value: [KisilerModel]())
    
    init(){
        kisilerListesi = krepo.kisilerListesi
    }
    
    func ara(aramaKelimesi:String){
        krepo.ara(aramaKelimesi: aramaKelimesi)
    }
    
    func sil(kisi:KisilerModel){
        krepo.sil(kisi: kisi)
        kisileriYukle()
    }
    
    func kisileriYukle(){
        krepo.kisileriYukle()
    }
}

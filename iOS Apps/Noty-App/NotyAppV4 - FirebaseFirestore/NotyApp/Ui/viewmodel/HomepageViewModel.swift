//
//  AnasayfaViewModel.swift
//  NotyApp
//
//  Created by Ege Özçelik on 2.12.2023.
//

import Foundation
import RxSwift

class HomepageViewModel{
    
    var mainrepo = MainRepository()
    var bannerrepo = BannerRepository()
    
    var notyList = BehaviorSubject<[Noty]>(value: [Noty]())
    var bannerList = BehaviorSubject<[Banner]>(value: [Banner]())
    init(){
        notyList = mainrepo.notyList
        bannerList = bannerrepo.bannerList
    }
    
    
    func getNotyList(){
        mainrepo.getNotyList()
    }
    
    func searchNoty(keyword:String){
        mainrepo.searchNoty(keyword: keyword)
    }
    
    func deleteNoty(noty:Noty){
        mainrepo.deleteNoty(noty: noty)
        //getNotyList()
    }
    
    
    func getBanners(){
        bannerrepo.getBanners()
    }
}

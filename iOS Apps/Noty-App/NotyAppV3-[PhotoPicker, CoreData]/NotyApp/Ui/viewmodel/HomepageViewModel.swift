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
    var notyList = BehaviorSubject<[NotyModel]>(value: [NotyModel]())
    
    init(){
        notyList = mainrepo.notyList
    }
    
    
    func getNotyList(){
        mainrepo.getNotyList()
    }
    
    func searchNoty(keyword:String){
        mainrepo.searchNoty(keyword: keyword)
    }
    
    func deleteNoty(noty:NotyModel){
        mainrepo.deleteNoty(noty: noty)
        getNotyList()
    }
}

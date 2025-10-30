//
//  Repository.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import Foundation
import RxSwift
import Alamofire

class Repository{
    var ItemsList = BehaviorSubject<[yemekler]>(value: [yemekler]())
    var BasketItemsList = BehaviorSubject<[sepet_yemekler]>(value: [sepet_yemekler]())
    var basket = [sepet_yemekler]()
    
    
    var getAllItemsRequest = "http://kasimadalan.pe.hu/yemekler/tumYemekleriGetir.php"
    var getBasketItemsRequest = "http://kasimadalan.pe.hu/yemekler/sepettekiYemekleriGetir.php"
    var addToBasketRequest = "http://kasimadalan.pe.hu/yemekler/sepeteYemekEkle.php"
    var deleteItemRequest = "http://kasimadalan.pe.hu/yemekler/sepettenYemekSil.php"
    
    var ud = UserDefaults.standard
    
    init(){
        GetBasketItems(kullaniciAdi: "egeozcelik")
    }
    
    func GetAllItems(){
        AF.request(getAllItemsRequest,method: .get).response{
            response in
            if let data = response.data{
                do{
                    let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
                    if let list = response.yemekler{
                        self.ItemsList.onNext(list)
                    }
                }catch{
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    
    func AddToBasket(yemek_adi:String, yemek_resim_adi:String, yemek_fiyat:Int, yemek_siparis_adet:Int, kullanici_adi:String){
       
        var UpdatedCount:Int?
        var isExisted = false
        
        
        for items in self.basket{
            if items.yemek_adi == yemek_adi{
                UpdatedCount = Int(items.yemek_siparis_adet!)! + yemek_siparis_adet
                isExisted = true
                DeleteItem(sepet_yemek_id: Int(items.sepet_yemek_id!)!, kullanici_adi: kullanici_adi)
                break
            }
        }
        
    
        if isExisted {
            let params:Parameters = ["yemek_adi":yemek_adi, "yemek_resim_adi":yemek_resim_adi, "yemek_fiyat":yemek_fiyat, "yemek_siparis_adet": UpdatedCount ?? 0 , "kullanici_adi":kullanici_adi]
            AF.request(addToBasketRequest, method: .post, parameters: params).response{
                response in
                if let data = response.data{
                    do{
                        let _response = try JSONDecoder().decode(CRUDResponse.self, from: data)
                        print(_response.success!)
                        print(_response.message!)
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            }
        }else{
            //STARTS
            let params:Parameters = ["yemek_adi":yemek_adi, "yemek_resim_adi":yemek_resim_adi, "yemek_fiyat":yemek_fiyat, "yemek_siparis_adet":yemek_siparis_adet, "kullanici_adi":kullanici_adi]
            AF.request(addToBasketRequest, method: .post, parameters: params).response{
                response in
                if let data = response.data{
                    do{
                        let _response = try JSONDecoder().decode(CRUDResponse.self, from: data)
                        print(_response.success!)
                        //print(_response.message!)
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            }
            //ENDS
        }
    }
    
    func DeleteItem(sepet_yemek_id:Int, kullanici_adi:String){
        let params:Parameters = ["sepet_yemek_id":sepet_yemek_id, "kullanici_adi":kullanici_adi]
        AF.request(deleteItemRequest, method: .post, parameters: params).response{
            response in
            if let data = response.data{
                do {
                    let _response = try JSONDecoder().decode(CRUDResponse.self, from: data)
                    print(_response.success!)
                    print(_response.message!)
                }catch{
                    
                    print(error.self)
                }
            }
        }
    }
    
    func GetBasketItems(kullaniciAdi:String){
        var total = 0
        var ordercount = 0
        let params:Parameters = ["kullanici_adi":kullaniciAdi]
        AF.request(getBasketItemsRequest, method: .post, parameters: params).response{
            response in
            if let data = response.data{
                do{
                    let response = try JSONDecoder().decode(BasketItemsResponse.self, from: data)
                    if let list = response.sepet_yemekler{
                        for item in list{
                            self.basket.append(item)
                            total = total + Int(item.yemek_siparis_adet!)!
                            ordercount = ordercount + (Int(item.yemek_siparis_adet!)! * Int(item.yemek_fiyat!)!)
                            print(" item count \(list.count)")
                        }
                        
                        self.ud.set(total, forKey: "itemCount")
                        self.ud.set(ordercount, forKey: "ordercount")
                        self.BasketItemsList.onNext(list)
                    }
                }catch{
                    self.ud.set(0, forKey: "itemCount")
                    self.ud.set(ordercount, forKey: "ordercount")
                    let list = [sepet_yemekler]()
                    self.BasketItemsList.onNext(list)
                    print("get basket items error")
                    
                }
            }
        }
        
    }
    func SearchItems(searchText:String){
        AF.request(getAllItemsRequest,method: .get).response{
            response in
            if let data = response.data{
                do{
                    let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
                    if let list = response.yemekler{
                        let filter = list.filter({$0.yemek_adi!.contains(searchText)})
                        self.ItemsList.onNext(filter)
                        for item in filter{
                            print(item.yemek_adi!)
                        }
                    }
                    
                }catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    
}

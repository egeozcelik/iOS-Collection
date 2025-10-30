//
//  ItemDetails.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import UIKit
import Kingfisher
class ItemDetails: UIViewController {

    
    @IBOutlet weak var imageViewItem: UIImageView!
    @IBOutlet weak var labelPrice: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelItemCount: UILabel!
    var viewmodel = ItemDetailsViewModel()
    var item:yemekler?
    let ud = UserDefaults.standard

    var amount = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelItemCount.text = String(amount)
        
        if let i = item{
            labelPrice.text = "\(i.yemek_fiyat!) ₺"
            labelName.text = i.yemek_adi
            imageViewItem.kf.setImage(with: URL(string: "http://kasimadalan.pe.hu/yemekler/resimler/\(i.yemek_resim_adi!)"))
        }
        
        
    }
    
    @IBAction func btnMinus(_ sender: Any) {
        if amount < 0 {
            amount = 0
        }else{
            amount = amount - 1
        }
        
        labelItemCount.text = String(amount)
    }
    
    @IBAction func btnPlus(_ sender: Any) {
        amount = amount + 1
        
        labelItemCount.text = String(amount)
    }
    
    @IBAction func btnAddToBasket(_ sender: Any) {
        var ordercount = Int(ud.string(forKey: "ordercount")!)!
        if let name = item?.yemek_adi, let image = item?.yemek_resim_adi, let price = item?.yemek_fiyat{
            viewmodel.AddToBasket(yemek_adi: name, yemek_resim_adi: image, yemek_fiyat: Int(price) ?? 0, yemek_siparis_adet: amount, kullanici_adi: "egeozcelik")
            print("detaydan eklendi")
            self.ud.setValue(self.ud.integer(forKey: "itemCount") + amount, forKey: "itemCount")
            
            ordercount = ordercount + ((Int(price) ?? 0) * amount)
            self.ud.setValue(ordercount, forKey: "ordercount")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    

}

//
//  BasketPage.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import UIKit
import Kingfisher
class BasketPage: UIViewController {
    
    var itemCount:Int?
    var viewmodel = BasketPageViewModel()
    var repo = Repository()
    var basketItemsList = [sepet_yemekler]()
    var ordercount = 0
    
    let ud = UserDefaults.standard
    
    @IBOutlet weak var basketItemTableView: UITableView!
    @IBOutlet weak var labelSubTotal: UILabel!
    @IBOutlet weak var labelPayment: UILabel!
    @IBOutlet weak var labelFoodPoints: UILabel!
    
   
    
    override func viewDidLoad() {
        self.basketItemTableView.rowHeight = 150;
        super.viewDidLoad()
        viewmodel.GetBasketItems(kullaniciAdi: "egeozcelik")

        basketItemTableView.delegate = self
        basketItemTableView.dataSource = self
        changeBadgeValue()
        _ = viewmodel.basketItemsList.subscribe(onNext: {
            list in
            self.basketItemsList = list
            self.itemCount = list.count
            
            
            DispatchQueue.main.async{
                self.basketItemTableView.reloadData()
                self.changeBadgeValue()
            }
        })
    }
    
    func changeBadgeValue(){
        if let tabItems = tabBarController?.tabBar.items{
            let basketItem = tabItems[1]
            basketItem.badgeValue = "\(ud.integer(forKey: "itemCount"))"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewmodel.GetBasketItems(kullaniciAdi: "egeozcelik")
    }
    override func viewDidAppear(_ animated: Bool) {
        labelPayment.text = ud.string(forKey: "payment")
        labelSubTotal.text = "\(ud.string(forKey: "ordercount")!) ₺"
        labelFoodPoints.text = "★\(Double(ud.string(forKey: "ordercount")!)!/10.0)"
    }
    
    @IBAction func buttonOrder(_ sender: Any) {
        
        var totalordercount = ud.integer(forKey: "totalordercount")
        totalordercount = totalordercount + 1
        ud.setValue(totalordercount, forKey: "totalordercount")
        
        
        var foodpoints:Double = Double(ud.string(forKey: "foodpoints")!)!//Double
        foodpoints = foodpoints + (Double(ordercount)/10)
        ud.set("\(Int(foodpoints))", forKey: "foodpoints")
    }
}


extension BasketPage : UITableViewDelegate,UITableViewDataSource, BasketCellProtocol{
    
    func addToDeleteClick(indexPath: IndexPath) {
        let Alert = UIAlertController(title: "Remove from basket?", message: "This item will be removed from basket.", preferredStyle: .alert)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let AcceptAction = UIAlertAction(title: "Remove", style: .destructive){
        action in
            if let id = self.basketItemsList[indexPath.row].sepet_yemek_id{
                self.viewmodel.DeleteItem(sepet_yemek_id: Int(id) ?? 0, kullanici_adi: "egeozcelik")
                self.ordercount = (Int(self.ud.string(forKey: "ordercount")!)! - (Int(self.basketItemsList[indexPath.row].yemek_siparis_adet!)! * Int(self.basketItemsList[indexPath.row].yemek_fiyat!)!))
                self.ud.set(self.ordercount, forKey: "ordercount")
                self.labelSubTotal.text = self.ud.string(forKey: "ordercount")
                self.labelFoodPoints.text = "\(Double(self.ud.string(forKey: "ordercount")!)!/10.0)"
                self.changeBadgeValue()
                self.viewmodel.GetBasketItems(kullaniciAdi: "egeozcelik")
            }
        }
        Alert.addAction(AcceptAction)
        Alert.addAction(CancelAction)
        self.present(Alert, animated:true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return basketItemsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = basketItemTableView.dequeueReusableCell(withIdentifier: "basketItemsCell", for: indexPath) as! BasketItemsCell
        let item = basketItemsList[indexPath.row]
        cell.labelName.text = "\(item.yemek_adi!)"
        cell.labelAmount.text = "\(item.yemek_siparis_adet!) pcs"
        cell.labelPrice.text = "\(item.yemek_fiyat!) ₺"
        cell.imageViewBasketItem.kf.setImage(with: URL(string: "http://kasimadalan.pe.hu/yemekler/resimler/\(item.yemek_resim_adi!)"))
        
        cell.indexPath = indexPath
        cell.basketCellProtocol = self
        
        
        
        return cell
    }
    
    
}

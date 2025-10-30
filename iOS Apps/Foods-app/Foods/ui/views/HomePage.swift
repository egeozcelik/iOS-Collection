//
//  ViewController.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import UIKit
import Kingfisher
class HomePage: UIViewController {
    
    @IBOutlet weak var labelFoodPoints: UILabel!
    @IBOutlet weak var labelUsername: UILabel!
    var viewmodel = HomePageViewModel()
    @IBOutlet weak var ItemsCollectionView: UICollectionView!
    
    @IBOutlet weak var labelCity: UILabel!
    @IBOutlet weak var labelTotalCart: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    var itemsList = [yemekler]()
    let ud = UserDefaults.standard
    
    var itemCount:Int?
    let imageBaseUrl = URL(string: "http://kasimadalan.pe.hu/yemekler/resimler/")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ud.set("Guest", forKey: "user1")
        labelCity.text = ud.string(forKey: "city")
        ItemsCollectionView.delegate = self
        ItemsCollectionView.dataSource = self
        
        
        
        
        _ = viewmodel.itemsList.subscribe(onNext: { list in
            self.itemsList = list
            DispatchQueue.main.async{
                self.ItemsCollectionView.reloadData()
            }
        })
        
        
        let collectionViewDesign = UICollectionViewFlowLayout()
        collectionViewDesign.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        collectionViewDesign.minimumLineSpacing = 5
        collectionViewDesign.minimumInteritemSpacing = 5
        
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 30) / 3
        
        collectionViewDesign.itemSize = CGSize(width: itemWidth, height: itemWidth*1.8)
        ItemsCollectionView.collectionViewLayout = collectionViewDesign
        
        if let tabItems = tabBarController?.tabBar.items{
            let basketItem = tabItems[1]
            basketItem.badgeValue = "\(ud.integer(forKey: "itemCount"))"
        }
        changeBadgeValue()
    }
    
    func changeBadgeValue(){
        if let tabItems = tabBarController?.tabBar.items{
            let basketItem = tabItems[1]
            basketItem.badgeValue = "\(ud.integer(forKey: "itemCount"))"
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        viewmodel.GetAllItems()
        changeBadgeValue()
        self.labelTotalCart.text = "Total: \(self.ud.string(forKey: "ordercount")!)₺"
    }
    override func viewDidAppear(_ animated: Bool) {
        if self.ud.string(forKey: "user1") == "Guest"{
            userlogin()
        }else{
            print("loggined as \(self.ud.string(forKey: "user1")!)")
        }
        ud.string(forKey: "user1") == "Guest" ? (labelUsername.text = "")  : (labelUsername.text = ud.string(forKey: "user1"))
        ud.string(forKey: "user1") == "Guest" ? (labelFoodPoints.text = "")  : (labelFoodPoints.text = "\(ud.string(forKey: "foodpoints")!)★")
    }
    func userlogin(){        
        let alert = UIAlertController(title: "Loginned as \(self.ud.string(forKey: "user1")!)", message: "Do you want to login?", preferredStyle: .alert)
        
        self.present(alert, animated: true)
        let StayAction = UIAlertAction(title: "Stay", style: .cancel){ _ in
            print("iptal seçildi")
        }
        alert.addAction(StayAction)
        
        let ChangeAction = UIAlertAction(title: "Change User", style: .destructive){ _ in
            
            self.performSegue(withIdentifier: "toLogin", sender: nil)
            }
        alert.addAction(ChangeAction)
    }
}

extension HomePage: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == ""{
            viewmodel.GetAllItems()
        }else{
            viewmodel.SearchItems(searchText: searchText)
        }
        
    }
}
    
extension HomePage: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "allItemsCell", for: indexPath) as! AllItemsCell
        
        let item = itemsList[indexPath.row]
        cell.labelPrice.text = "\(item.yemek_fiyat!) ₺"
        cell.labelName.text = "\(item.yemek_adi!)"
        if let url = URL(string: "http://kasimadalan.pe.hu/yemekler/resimler/\(item.yemek_resim_adi!)"){
            DispatchQueue.main.async{
                cell.imageViewItem.kf.setImage(with: url)
            }
        }
        cell.indexPath = indexPath
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = itemsList[indexPath.row]
        performSegue(withIdentifier: "toDetail", sender: item)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail"{
            if let item = sender as? yemekler{
                let nextVC = segue.destination as! ItemDetails
                nextVC.item = item
            }
            
        }
    }
    
     
}

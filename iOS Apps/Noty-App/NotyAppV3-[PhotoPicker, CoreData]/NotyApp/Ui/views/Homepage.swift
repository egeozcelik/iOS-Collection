//
//  ViewController.swift
//  NotyApp
//
//  Created by Ege Özçelik on 28.11.2023.
//

import UIKit
import RxSwift


class Homepage: UIViewController {

    var notyList = [NotyModel]()
    var homepageViewModel = HomepageViewModel()
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var notyTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        _ = homepageViewModel.notyList.subscribe(onNext: { list in
            self.notyList = list
            self.notyTableView.reloadData()
        })
        
        notyTableView.delegate = self
        notyTableView.dataSource = self
        searchBar.delegate = self
        
        
    }
    
   
    
    override func viewDidAppear(_ animated: Bool) {
        //viewdidload yerine burada çağırıyorum. İleride ekleme yaptığımda listemi güncel halini görmek istersem, anasayfaya tekrar geldiğimde bu fonksiyon çalışacak
        homepageViewModel.getNotyList()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }


}


extension Homepage : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            homepageViewModel.getNotyList()
        }else{
            homepageViewModel.searchNoty(keyword: searchText)
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }
   
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

extension Homepage : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notyList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notyCell") as! NotyCell
        
        let noty = notyList[indexPath.row]
        
        cell.imageViewNoty.image = UIImage(named: noty.resim!)
        cell.labelDers.text = noty.ders
        cell.labelKonu.text = noty.konu
        cell.labelSayfa.text = "\(noty.sayfaAdet) sayfa"
        cell.labelYazar.text = "\(noty.yazar!)"
        cell.labelIndirme.text = " \(noty.indirme)↓ "
        cell.labelFiyat.text = " \(noty.fiyat)₺ "
        
        //cell.backgroundColor = UIColor(white: 0.9, alpha: 1)
        //cell.background.layer.cornerRadius = 10
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let noty = notyList[indexPath.row]
        performSegue(withIdentifier: "toNotyDetail", sender: noty)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNotyDetail"{
            if let noty = sender as? NotyModel{
                let nextVC = segue.destination as! NotyDetail
                nextVC.noty = noty
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete"){ contextualAction,view,bool in
            let noty = self.notyList[indexPath.row]
            
            let alert = UIAlertController(title: "Deleting", message: "Are you sure want to delete \(noty.konu!) noty?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(cancelAction)
            
            let acceptAction = UIAlertAction(title: "Accept", style: .destructive){ action in
                self.homepageViewModel.deleteNoty(noty: noty)
            }
            alert.addAction(acceptAction)
            
            self.present(alert, animated: true)
        }
            
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
        
}


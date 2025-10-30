//
//  NotyDetail.swift
//  NotyApp
//
//  Created by Ege Özçelik on 28.11.2023.
//

import UIKit

class NotyDetail: UIViewController {

    var noty:NotyModel?
    
    @IBOutlet weak var imageViewNoty: UIImageView!
    
    @IBOutlet weak var labelKonu: UILabel!
    @IBOutlet weak var labelDers: UILabel!
    @IBOutlet weak var labelSayfa: UILabel!
    @IBOutlet weak var labelIndirme: UILabel!
    @IBOutlet weak var labelYazar: UILabel!
    
    @IBOutlet weak var labelFiyat: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = noty?.resim, let ders = noty?.ders, let konu = noty?.konu, let sayfa = noty?.sayfaAdet, let yazar = noty?.yazar, let indirme = noty?.indirme, let fiyat = noty?.fiyat{
            imageViewNoty.image = UIImage(named: image)
            labelDers.text = "Ders: \(ders)"
            labelKonu.text = "Konu: \(konu)"
            labelSayfa.text = "\(sayfa) sayfa"
            labelYazar.text = "Yazar: \(yazar)"
            labelIndirme.text = "\(indirme) kez indirildi"
            labelFiyat.text = "Ücret: \(fiyat)₺"
        }
        
        
        
    }
    

    @IBAction func btnSepeteEkle(_ sender: Any) {
    }
    
   

}

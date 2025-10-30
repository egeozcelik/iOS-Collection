//
//  NotyDetail.swift
//  NotyApp
//
//  Created by Ege Özçelik on 28.11.2023.
//

import UIKit

class NotyDetail: UIViewController {

    var noty:Noty?
    
    @IBOutlet weak var imageViewNoty: UIImageView!
    
    @IBOutlet weak var labelKonu: UILabel!
    @IBOutlet weak var labelDers: UILabel!
    @IBOutlet weak var labelSayfa: UILabel!
    @IBOutlet weak var labelIndirme: UILabel!
    @IBOutlet weak var labelYazar: UILabel!
    @IBOutlet weak var labelIcerik: UILabel!
    @IBOutlet weak var labelFiyat: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = noty?.resim, let ders = noty?.ders, let konu = noty?.konu, let sayfa = noty?.sayfaAdet, let yazar = noty?.yazar, let indirme = noty?.indirme, let fiyat = noty?.fiyat, let icerik = noty?.icerik{
            imageViewNoty.image = UIImage(named: image)
            labelDers.text = "\(ders)"
            labelKonu.text = "\(konu)"
            labelSayfa.text = "\(sayfa) sayfa"
            labelYazar.text = "\(yazar)"
            labelIndirme.text = "\(indirme) times downloaded"
            labelFiyat.text = " \(fiyat)₺"
            labelIcerik.text = "\(icerik)"
        }
        
        
        
    }
    

    @IBAction func btnSepeteEkle(_ sender: Any) {
    }
    
   

}

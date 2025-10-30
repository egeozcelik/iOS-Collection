//
//  KisiKayit.swift
//  KisilerUygulamasi
//
//  Created by Ege Özçelik on 21.09.2023.
//

import UIKit

class KisiKayit: UIViewController {
    
    @IBOutlet weak var tfKisiAd: UITextField!
    @IBOutlet weak var tfKisiTel: UITextField!
    
    
    var viewModel = KisiKayitViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func buttonKaydet(_ sender: Any) {
        if let ad = tfKisiAd.text, let tel = tfKisiTel.text{
            viewModel.kaydet(kisi_ad: ad, kisi_tel: tel)
        }
        
        
        
        
    }
    
}

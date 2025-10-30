//
//  KisiDetay.swift
//  KisilerUygulamasi
//
//  Created by Kasım on 21.09.2023.
//

import UIKit

class KisiDetay: UIViewController {

    @IBOutlet weak var tfKisiTel: UITextField!
    @IBOutlet weak var tfKisiAd: UITextField!
    
    var kisi:KisilerModel?
    
    var viewModel = KisiDetayViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let k = kisi {
            tfKisiAd.text = k.kisi_ad
            tfKisiTel.text = k.kisi_tel
        }
    }

    @IBAction func buttonGuncelle(_ sender: Any) {
        if let ad = tfKisiAd.text , let tel = tfKisiTel.text , let k = kisi {
            viewModel.guncelle(kisi: k, kisi_ad: ad, kisi_tel: tel)
        }
    }
}

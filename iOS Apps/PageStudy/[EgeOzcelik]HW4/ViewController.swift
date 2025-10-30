//
//  ViewController.swift
//  [EgeOzcelik]HW4
//
//  Created by Ege Özçelik on 18.09.2023.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func anasayfaButton(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
}


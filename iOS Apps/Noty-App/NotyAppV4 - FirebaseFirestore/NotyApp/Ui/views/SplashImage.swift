//
//  SplashImage.swift
//  NotyApp
//
//  Created by Ege Özçelik on 8.12.2023.
//

import UIKit

class SplashImage: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
            self.performSegue(withIdentifier: "toHomepage", sender: nil)
        }
      
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    


}

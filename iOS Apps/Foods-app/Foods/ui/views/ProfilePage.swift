//
//  ProfilePage.swift
//  Foods
//
//  Created by Ege Özçelik on 16.10.2023.
//

import UIKit

class ProfilePage: UIViewController {

    let ud = UserDefaults.standard
    
    @IBOutlet weak var labelUsername: UILabel!
    
    @IBOutlet weak var labelGender: UILabel!
    
    @IBOutlet weak var labelCity: UILabel!
    
    @IBOutlet weak var labelOrderCount: UILabel!
    
    @IBOutlet weak var labelFoodPoint: UILabel!
    
    
    @IBOutlet weak var imageGender: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let name = ud.string(forKey: "user1"), let gender = ud.string(forKey: "gender"), let city = ud.string(forKey: "city"), let ordercount = ud.string(forKey: "ordercount"), let foodpoints = ud.string(forKey: "foodpoints"){
            labelUsername.text = name
            labelCity.text = city
            labelGender.text = gender
            labelFoodPoint.text = "\(foodpoints)"
            labelOrderCount.text = "\(ordercount)"
            imageGender.image = UIImage(named: gender)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        if let name = ud.string(forKey: "user1"), let gender = ud.string(forKey: "gender"), let city = ud.string(forKey: "city"), let ordercount = ud.string(forKey: "totalordercount"), let foodpoints = ud.string(forKey: "foodpoints"){
            labelUsername.text = name
            labelCity.text = city
            labelGender.text = gender
            labelFoodPoint.text = "★\(foodpoints)"
            labelOrderCount.text = "\(ordercount)"
            imageGender.image = UIImage(named: gender)
        }
    }

  

}

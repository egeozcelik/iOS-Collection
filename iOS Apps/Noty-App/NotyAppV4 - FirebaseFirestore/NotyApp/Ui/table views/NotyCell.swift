//
//  NotyCell.swift
//  NotyApp
//
//  Created by Ege Özçelik on 28.11.2023.
//

import UIKit

class NotyCell: UITableViewCell {

    @IBOutlet weak var imageViewNoty: UIImageView!
    @IBOutlet weak var labelDers: UILabel!
    @IBOutlet weak var labelSayfa: UILabel!
    @IBOutlet weak var labelKonu: UILabel!
    @IBOutlet weak var labelYazar: UILabel!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var labelIndirme: UILabel!
    @IBOutlet weak var labelFiyat: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

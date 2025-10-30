//
//  GameCell.swift
//  AppStore[Clone]
//
//  Created by Ege Özçelik on 1.10.2023.
//

import UIKit

class GameCell: UITableViewCell {

    
    @IBOutlet weak var imageViewGame: UIImageView!
    
    @IBOutlet weak var labelGameName: UILabel!
    
    @IBOutlet weak var labelGameDesc: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

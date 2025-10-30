//
//  notyAnasayfaCellTableViewCell.swift
//  NotyWorkSpace
//
//  Created by Ege on 31.10.2024.
//

import UIKit

class notyAnasayfaCell: UITableViewCell {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var lecture: UILabel!
    @IBOutlet weak var pageCount: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  BasketItemsCell.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import UIKit

protocol BasketCellProtocol{
    func addToDeleteClick(indexPath:IndexPath)
}

class BasketItemsCell: UITableViewCell {
    
    
    @IBOutlet weak var imageViewBasketItem: UIImageView!
    
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelPrice: UILabel!
    @IBOutlet weak var labelAmount: UILabel!
    @IBOutlet weak var labelTotalPrice: UILabel!
    
    var basketCellProtocol:BasketCellProtocol?
    var indexPath:IndexPath?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0 ))
    }
    
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBAction func btnDelete(_ sender: Any) {
        basketCellProtocol?.addToDeleteClick(indexPath: indexPath!)
    }
}

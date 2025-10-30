//
//  CollectionViewCell.swift
//  Foods
//
//  Created by Ege Özçelik on 15.10.2023.
//

import UIKit

protocol CellProtocol{
    func addToBasketClick(indexPath:IndexPath)
}



class AllItemsCell: UICollectionViewCell {
   
    @IBOutlet weak var imageViewItem: UIImageView!
    
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelPrice: UILabel!
    
    var cellProtocol:CellProtocol?
    var indexPath:IndexPath?
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    @IBAction func btnAddBasket(_ sender: Any) {
        cellProtocol?.addToBasketClick(indexPath: indexPath!)
    }
    
    
    
    
}

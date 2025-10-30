//
//  NotyShare.swift
//  NotyWorkSpace
//
//  Created by Ege on 30.10.2024.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import Kingfisher


class NotyShare: UIViewController {

    @IBOutlet weak var notiesCollectionView: UICollectionView!
    @IBOutlet weak var tvLecture: UITextField!
    @IBOutlet weak var tvSubject: UITextField!
    let storage = Storage.storage()
    let authenticator = Authenticator()
    let dbService = FirestoreService()
    
    var selectedImages: [UIImage] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        notiesCollectionView.dataSource = self
        notiesCollectionView.delegate = self
        let collectionViewDesign = UICollectionViewFlowLayout()
        collectionViewDesign.scrollDirection = .horizontal
        collectionViewDesign.minimumLineSpacing = 5
        collectionViewDesign.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 0)
        collectionViewDesign.minimumInteritemSpacing = 0
        collectionViewDesign.itemSize = CGSize(width: 180, height: 250)
        notiesCollectionView.collectionViewLayout = collectionViewDesign
    }
    
    @IBAction func btnShare(_ sender: Any) {
        if tvLecture.text != "" && tvSubject.text != "" {
            CreateNewNoty()
        } else {
            let alert = UIAlertController(title: "Unable to Share Noty!", message: "Please fill the Lecture and Subject fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okey", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func CreateNewNoty() {
        if let lecture = tvLecture.text, let subject = tvSubject.text, let author = authenticator.getLoggedInUser() {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            dbService.convertImagesToURLs(images: selectedImages) { urls in
                let newNoty = Noty(
                    id: "",
                    author: author,
                    lecture: lecture,
                    subject: subject,
                    datePosted: dateFormatter.string(from: Date()),
                    images: urls,
                    pageCount: "\(urls.count)"
                )
                self.dbService.saveNoty(noty: newNoty)
            }
        }
    }
}

extension NotyShare: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotyCell", for: indexPath) as! notyCell
        
        cell.notyImage.image = selectedImages[indexPath.row]
        return cell
    }
}

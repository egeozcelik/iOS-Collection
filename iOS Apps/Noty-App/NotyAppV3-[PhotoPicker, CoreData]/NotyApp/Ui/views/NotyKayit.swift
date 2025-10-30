//
//  NotyKayit.swift
//  NotyApp
//
//  Created by Ege Özçelik on 2.12.2023.
//

import UIKit
import PhotosUI
class NotyKayit: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var tfDers: UITextField!
    @IBOutlet weak var tfKonu: UITextField!
    @IBOutlet weak var segmentedUcret: UISegmentedControl!

    @IBOutlet weak var notyImageCollectionView: UICollectionView!
    
    var viewModel = NotyKayitViewModel()
    var fiyat:Int?
    
    
    
    var imageArr = [UIImage]()//[UIImage(named: "img1"),UIImage(named: "img2"),UIImage(named: "img3"),UIImage(named: "img4"),UIImage(named: "img5")]
    
    let lessons = ["math", "history", "science", "languageArts", "physics", "chemistry"]
    var pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissions()
        
        
        fiyat = 10
        pickerView.delegate = self
        pickerView.dataSource = self
        
        notyImageCollectionView.delegate = self
        notyImageCollectionView.dataSource = self
        
        let collectionViewDesign = UICollectionViewFlowLayout()
        collectionViewDesign.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 0)
        collectionViewDesign.minimumLineSpacing = 5
        collectionViewDesign.minimumInteritemSpacing = 0
        collectionViewDesign.scrollDirection = .horizontal
        collectionViewDesign.itemSize = CGSize(width: 160, height: 230)
        notyImageCollectionView.collectionViewLayout = collectionViewDesign
        
        
        tfDers.inputView = pickerView
        tfDers.delegate = self
        tfKonu.delegate = self
       
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @IBAction func segmentedTrigger(_ sender: UISegmentedControl){
        let choosenIndex = sender.selectedSegmentIndex
        
        switch choosenIndex {
        case 0: 
            fiyat = 10
        case 1:
            fiyat = 20
        case 2:
            fiyat = 50
        case 3:
            fiyat = 100
        default:
            fiyat = 10
        }
        
        
    }

    func checkPermissions(){
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized{
            PHPhotoLibrary.requestAuthorization({
                (status: PHAuthorizationStatus) -> Void in ()
            })
        }
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized{
        }else{
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus){
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized{
            print("Access granted to use Photo Library")
        }else{
            print("We don't have access to your Photos")
        }
    }
    
    @IBAction func btnPhotos(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
        
        
        let phPickerVC = PHPickerViewController(configuration: config)
        phPickerVC.delegate = self
        self.present(phPickerVC, animated: true)
    }
    
    @IBAction func btnCamera(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
        
    }
    
    @IBAction func btnNotyKayit(_ sender: Any) {
        if let ders = tfDers.text, let konu = tfKonu.text, let secilenFiyat = fiyat{
            let newNoty = Noty(id: 8, ders: ders, konu: konu, resim: "img4", sayfaAdet: imageArr.count, yazar: "egeozcelik", indirme: 12, fiyat: secilenFiyat)
            viewModel.addNoty(newNoty: newNoty)
            performSegue(withIdentifier: "toHomepage", sender: nil)
        }
        
    }
    
}


extension NotyKayit: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return lessons.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return lessons[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tfDers.text = lessons[row]
        tfDers.resignFirstResponder()
    }
}

extension NotyKayit: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        return imageArr.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "notyKayitImagesCell", for: indexPath) as! NotyKayitImagesCell
        
        cell.notyImage.image = imageArr[indexPath.row]
        return cell
    }
    
    
}

extension NotyKayit: PHPickerViewControllerDelegate{
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self){object, error in
                
                if let image = object as? UIImage{
                    if(self.imageArr.count < 10){
                        self.imageArr.append(image)
                    }
                    
                }
                
                DispatchQueue.main.async {
                    self.notyImageCollectionView.reloadData()
                }
                
            }
        }
        
    }

}

extension NotyKayit: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let addedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        self.imageArr.append(addedImage!)
        picker.dismiss(animated: true)
        
        DispatchQueue.main.async{
            self.notyImageCollectionView.reloadData()
        }
    }
}

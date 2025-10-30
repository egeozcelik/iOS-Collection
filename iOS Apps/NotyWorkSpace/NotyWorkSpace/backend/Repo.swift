import UIKit
import Foundation
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import RxSwift


class FirestoreService {
    private let notyCollection = Firestore.firestore().collection("noties")
    let notyList = BehaviorSubject<[Noty]>(value: [Noty]())
    
    private let storage = Storage.storage()
    
    
    
    func getNotyList() {
        let query = notyCollection.order(by: "author", descending: true)
        
        query.addSnapshotListener { snapshot, error in
            var list = [Noty]()
            
            if let documents = snapshot?.documents {
                let dispatchGroup = DispatchGroup()
                
                for document in documents {
                    dispatchGroup.enter()
                    
                    let data = document.data()
                    let id = document.documentID
                    let author = data["author"] as? String ?? ""
                    let lecture = data["lecture"] as? String ?? ""
                    let subject = data["subject"] as? String ?? ""
                    let date = data["datePosted"] as? String ?? ""
                    let pageCount = data["pageCount"] as? String ?? ""
                    let imageUrls = data["images"] as? [String] ?? []
                    
                    
                    let noty = Noty(id: id, author: author, lecture: lecture, subject: subject, datePosted: date, images: imageUrls, pageCount: pageCount)
                    list.append(noty)
                }
                if list.isEmpty {
                    let noty = Noty(id: "", author: "", lecture: "", subject: "", datePosted: "", images: [], pageCount: "")
                    //dispatchGroup.leave()
                    list.append(noty)
                }else{
                    self.notyList.onNext(list)
                    //dispatchGroup.leave()
                    print("Total Noties loaded from DB: \(list.count)")
                }
                
            }
        }
    }
    private func fetchImages(from urls: [String], completion: @escaping ([UIImage]) -> Void) {
        var images = [UIImage]()
        let dispatchGroup = DispatchGroup()
        
        for url in urls {
            dispatchGroup.enter()
            
            let storageRef = Storage.storage().reference(forURL: url)
            storageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
                if let data = data, let image = UIImage(data: data) {
                    images.append(image)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(images)
        }
    }
    
    func convertImagesToURLs(images: [UIImage], completion: @escaping ([String]) -> Void) {
        var imageUrls: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            let imageRef = storage.reference().child("notyImages/\(UUID().uuidString)_\(index).jpg")
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Image conversion to data failed.")
                dispatchGroup.leave()
                continue
            }
            
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error fetching download URL: \(error.localizedDescription)")
                    } else if let url = url {
                        imageUrls.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(imageUrls)
        }
    }
    
    func saveNoty(noty: Noty) {
        let author = noty.author
        let lecture = noty.lecture
        let subject = noty.subject
        let date = noty.datePosted
        let images = noty.images

        let addedNoty: [String: Any] = [
            "id": "",
            "author": author,
            "lecture": lecture,
            "subject": subject,
            "datePosted": date,
            "pageCount": "\(images.count)",
            "images": images
        ]
            
        self.notyCollection.document().setData(addedNoty)
        
    }
}
class Authenticator {
    
    init() {
        setDefaultUsers()
    }
    
    private func setDefaultUsers() {
        let users = [
            ("egeozc", "ege1699ege"),
            ("elifturku", "123ET"),
            ("bernaibrahimli", "123BI")
        ]
        
        for (index, user) in users.enumerated() {
            UserDefaults.standard.set(user.0, forKey: "usr\(index+1)")
            UserDefaults.standard.set(user.1, forKey: "usr\(index+1)psw")
        }
    }
    
    func loginUser(name: String, psw: String) -> Bool {
        for i in 1...3 {
            if let storedUser = UserDefaults.standard.string(forKey: "usr\(i)"),
               let storedPassword = UserDefaults.standard.string(forKey: "usr\(i)psw"),
               storedUser == name, storedPassword == psw {
                
                UserDefaults.standard.set(name, forKey: "loggedInUser")
                return true
            }
        }
        return false
    }
    
    func getLoggedInUser() -> String? {
        return UserDefaults.standard.string(forKey: "loggedInUser")
    }
    
    func logoutUser() {
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
    }
    
    func showAlert(on viewController: UIViewController, message: String) {
        let alert = UIAlertController(title: "Bilgi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}

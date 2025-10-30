import UIKit
import Foundation
import PhotosUI
import RxSwift
import Kingfisher
class Anasayfa: UIViewController, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnShareOutlet: UIBarButtonItem!
    @IBOutlet weak var btnLoginOutlet: UIBarButtonItem!
        
    let service = Authenticator()
    let dbService = FirestoreService()
    let notyService = FirestoreService()
    var selectedImages: [UIImage] = []
    var notyList = [Noty]()
    
    @IBOutlet weak var notyTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notyTableView.dataSource = self
        notyTableView.delegate = self
        
        if let loggedInUser = service.getLoggedInUser() {
            setLoggedInUser(loggedInUser)
        } else {
            resetLoginButton()
        }

        loadNotyList()
    }
    func loadNotyList() {
        //loadingIndicator.startAnimating()

        dbService.getNotyList()
        
        _ = dbService.notyList.subscribe(onNext: { [weak self] list in
            guard let self = self else { return }
            
            self.notyList = list
            
            DispatchQueue.main.async {
                self.notyTableView.reloadData()
                self.loadingIndicator.stopAnimating()
            }
        }, onError: { error in
            print("Error fetching noty list: \(error)")
            self.loadingIndicator.stopAnimating()
        })
    }

    @IBAction func BtnLogin(_ sender: Any) {
        if let loggedInUser = service.getLoggedInUser() {
            showLogoutAlert(for: loggedInUser)
        } else {
            promptForLogin()
        }
    }
    
    @IBAction func BtnShare(_ sender: Any) {
        openPhotoPicker(on: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toNotyShare" {
                if let nextVC = segue.destination as? NotyShare {
                    nextVC.selectedImages = selectedImages
            }
        }
    }
    
    func openPhotoPicker(on viewController: UIViewController) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 6
        config.filter = .images
                

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        viewController.present(picker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        selectedImages = []
        let group = DispatchGroup()
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                defer { group.leave() } // Yeni ekleme
                if let image = object as? UIImage {
                    self?.selectedImages.append(image)
                }
            }
        }
        group.notify(queue: .main) { // Yeni ekleme
            self.performSegue(withIdentifier: "toNotyShare", sender: nil)
        }
    }
    
    private func promptForLogin() {
        let alert = UIAlertController(title: "Giriş Yap", message: "Kullanıcı adı ve şifre girin.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Kullanıcı adı"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Şifre"
            textField.isSecureTextEntry = true
        }
        
        let loginAction = UIAlertAction(title: "Giriş", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let username = alert.textFields?[0].text ?? ""
            let password = alert.textFields?[1].text ?? ""
            //loadingIndicator.startAnimating()
            
            if self.service.loginUser(name: username, psw: password) {
                self.setLoggedInUser(username)
            } else {
                self.service.showAlert(on: self, message: "Kullanıcı adı veya şifre yanlış.")
            }
            loadingIndicator.stopAnimating()
        }
        
        alert.addAction(loginAction)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showLogoutAlert(for username: String) {
        let alert = UIAlertController(title: "Çıkış Yap", message: "\(username) adlı kullanıcıdan çıkış yapmak istiyor musunuz?", preferredStyle: .alert)
        
        let logoutAction = UIAlertAction(title: "Çıkış Yap", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.service.logoutUser()
            self.resetLoginButton()
        }
        
        alert.addAction(logoutAction)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func setLoggedInUser(_ username: String) {
        btnLoginOutlet.title = username
        btnShareOutlet.isEnabled = true
        
    }
    
    private func resetLoginButton() {
        btnLoginOutlet.title = "Giriş Yap"
        btnShareOutlet.isEnabled = false
    }
}
extension Anasayfa:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notyList.count
    }
    
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotyAnasayfaCell", for: indexPath) as! notyAnasayfaCell
        let noty = notyList[indexPath.row]
    
        if let imageUrlString = noty.images.first, let imageUrl = URL(string: imageUrlString) {
            cell.img.kf.setImage(with: imageUrl, placeholder: UIImage(named: "placeholder"))
        }else {
            cell.img.image = UIImage(named: "defaultImgForNoty")
        }
       
        cell.lecture.text = noty.lecture
        cell.subject.text = noty.subject
        cell.pageCount.text = noty.pageCount
        
        return cell
        
    }
}

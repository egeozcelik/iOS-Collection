//
//  NotKayit.swift
//  ToDo-App
//
//  Created by Ege Özçelik on 3.10.2023.
//

import UIKit

class NotKayit: UIViewController {

    
    @IBOutlet weak var tfTodo: UITextField!
    
    var viewModel = NotKayitViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

    @IBAction func btnKaydet(_ sender: Any) {
        if let todo = tfTodo.text{
            viewModel.kaydet(todo: todo)
        }
        
        navigationController?.popToRootViewController(animated: true)
    }
}

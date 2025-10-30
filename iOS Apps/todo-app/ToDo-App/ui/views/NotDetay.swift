//
//  NotDetay.swift
//  ToDo-App
//
//  Created by Ege Özçelik on 3.10.2023.
//

import UIKit

class NotDetay: UIViewController {

    
    @IBOutlet weak var tfToDoAd: UITextField!
    var todo : ToDos?
    var viewModel = NotDetayViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let td = todo{
            tfToDoAd.text = td.name
        }
    }
    

    @IBAction func btnUpdate(_ sender: Any) {
        if let _todo = tfToDoAd.text, let t = todo{
            viewModel.guncelle(todo_id: t.id!, todo: _todo)
        }
        navigationController?.popToRootViewController(animated: true)
    }
    

}

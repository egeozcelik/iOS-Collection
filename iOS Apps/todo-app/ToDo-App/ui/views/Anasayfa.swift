//
//  ViewController.swift
//  ToDo-App
//
//  Created by Ege Özçelik on 3.10.2023.
//

import UIKit

class Anasayfa: UIViewController {

    @IBOutlet weak var todosTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var todoCount: UILabel!
    
    
    var todoListesi = [ToDos]()
    
    var viewModel = AnasayfaViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField

        textFieldInsideSearchBar?.textColor = UIColor(named: "foreground")
        
        
        searchBar.delegate = self
        todosTableView.dataSource = self
        todosTableView.delegate = self
        
        _ = viewModel.todoListesi.subscribe( onNext: {
            liste in
            self.todoListesi = liste
            self.todosTableView.reloadData()
        })
        
        todoCount.text = String(todoListesi.count)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.todoYukle()
        todoCount.text = String(todoListesi.count)
    }
    
    @IBAction func btnNew(_ sender: Any) {
        performSegue(withIdentifier: "toKayit", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetay" {
            if let todo = sender as? ToDos{
                let gidilecekVC = segue.destination as! NotDetay
                gidilecekVC.todo = todo
            }
        }
    }
    
}

extension Anasayfa: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.ara(aramaKelimesi: searchText)
    }
}

extension Anasayfa:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoListesi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notHucre") as! NotHucre
        
        let todo = todoListesi[indexPath.row]
        
        cell.labelTodo.text = todo.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todo = todoListesi[indexPath.row]
        performSegue(withIdentifier: "toDetay", sender: todo)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        
        let silAction = UIContextualAction(style: .destructive, title: "Sil"){
            UIContextualAction,view,bool in
            
            let todo = self.todoListesi[indexPath.row]
            let alert = UIAlertController(title: "Deleting", message: "Are you sure want to delete?", preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let delete = UIAlertAction(title: "Accept", style: .destructive){
                action in
                self.viewModel.sil(todo_id: todo.id!)
                self.todoCount.text = String(self.todoListesi.count)
            }
            alert.addAction(cancel)
            alert.addAction(delete)
            self.present(alert, animated: true)
        }
        
        
        
        return UISwipeActionsConfiguration(actions: [silAction])
    }
    
}


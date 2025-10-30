
import Foundation
import RxSwift

class ToDoRepository{
    var todoListesi = BehaviorSubject<[ToDos]>(value: [ToDos]())
    let db:FMDatabase?
    init(){
        let hedefYol = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let veritabaniURL = URL(fileURLWithPath: hedefYol).appendingPathComponent("todo.sqlite")
        db = FMDatabase(path: veritabaniURL.path)
    }
    
    func kaydet(todo:String){
        db?.open()
        
        do{
            try db?.executeUpdate("INSERT INTO notlar (name) VAlUES(?)", values: [todo])
        }catch{
            print(error.localizedDescription)
        }
        db?.close()
    }
    
    func guncelle(td_id:Int, todo:String){
        db?.open()
        
        do{
            try db?.executeUpdate("UPDATE notlar SET name=? WHERE id=?", values: [todo, td_id])
        }catch{
            print(error.localizedDescription)
        }
        db?.close()
    }
    
    func ara(aramaKelimesi:String){
        db?.open()
        
        var liste = [ToDos]()
        
        do{
            let rs = try db!.executeQuery("SELECT * FROM notlar WHERE name like '%\(aramaKelimesi)%' ", values: nil)
            while rs.next(){
                let todo_id = Int(rs.string(forColumn: "id"))!
                let todo_name = rs.string(forColumn: "name")!
                
                let todo = ToDos(id: todo_id, name: todo_name)
                liste.append(todo)
            }
            todoListesi.onNext(liste)
        }
        catch{
            print(error.localizedDescription)
        }
        db?.close()
    }
    
    func sil(todo_id:Int)
    {
        db?.open()
        do{
            try db!.executeUpdate("DELETE FROM notlar WHERE id=?", values: [todo_id])
        }catch{
            print(error.localizedDescription)
        }
        db?.close()
    }
    
    func todoYukle(){
        
        db?.open()
        var liste = [ToDos]()
        do{
            let rs = try db!.executeQuery("SELECT * FROM notlar", values: nil)
            while rs.next(){
                let todo_id = Int(rs.string(forColumn: "id"))!
                let todo_name = rs.string(forColumn: "name")!
                
                let todo = ToDos(id: todo_id, name: todo_name)
                liste.append(todo)
            }
            todoListesi.onNext(liste)
        }
        catch{
            print(error.localizedDescription)
        }
        db?.close()
    }
    
    func veritabaniKopyala(){
            let bundleYolu = Bundle.main.path(forResource: "todo", ofType: ".sqlite")
            let hedefYol = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let kopyalanacakYer = URL(fileURLWithPath: hedefYol).appendingPathComponent("todo.sqlite")
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: kopyalanacakYer.path){
                print("Veritabanı zaten var")
            }else{
                do{
                    try fileManager.copyItem(atPath: bundleYolu!, toPath: kopyalanacakYer.path)
                }catch{}
            }
        }
}


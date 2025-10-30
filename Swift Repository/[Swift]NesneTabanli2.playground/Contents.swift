import UIKit

//Inheritance, bir class başka bir class'a özellik aktarıyor

//superclass : üst sınıf
//subclass : alt sınıf

//

class Ev{
    var pencereSayisi:Int?
    init(pencereSayisi:Int){
        self.pencereSayisi = pencereSayisi
    }
}
class Saray : Ev{
    var kuleSayisi:Int?
    
    init(kuleSayisi:Int, pencereSayisi:Int){
        self.kuleSayisi = kuleSayisi
        super.init(pencereSayisi: pencereSayisi)//super Keyword
    }
}
class Villa:Ev{
    var garajVarmi:Bool?
    
    init(garajVarmi:Bool, pencereSayisi:Int){
        self.garajVarmi = garajVarmi
        super.init(pencereSayisi: pencereSayisi)
    }
}

let topkapiSarayi = Saray(kuleSayisi: 5, pencereSayisi: 300)
let bogazVilla = Villa(garajVarmi: true, pencereSayisi: 50)

print(topkapiSarayi.kuleSayisi!)
print(topkapiSarayi.pencereSayisi!)

print(bogazVilla.garajVarmi!)
print(bogazVilla.pencereSayisi!)

//Upcasting
//Saray -> Ev

let ev = Saray(kuleSayisi: 3, pencereSayisi: 100) as Ev // düz eve dönüştürdüm


//Downcasting
//Ev > Saray
let saray = Ev(pencereSayisi: 40) as? Saray //as! Saray

//? varsa bir hata olduğunda saray = nil olacak
// ! varsa bir hata olduğunda uygulama çökecek


//Tip Kontrol
if ev is Ev{//instanceOf(java)
    print("Nesne ev Sınıfından Türetilmiştir.")
}else{
    print("Nesne ev Sınıfından türetilmemiştir.")
}


//Override Kullanımı

class Hayvan{
    func sesCikar(){
        print("Sesim Yok")
    }
}
class Memeli:Hayvan{

}
class Kedi:Memeli{
    override func sesCikar() {
        print("Miyav Miyav!")
    }
}
class Kopek:Memeli{
    override func sesCikar() {
        print("Hav hav!")
    }
}


let hayvan = Hayvan()
let memeli = Memeli()
let kedi = Kedi()
let köpek  = Kopek()

hayvan.sesCikar() //Kalıtım yok, kendi metoduna erişti
memeli.sesCikar() //Kalıtım var, üst sınıfın metoduna erişti
kedi.sesCikar()   //Kalıtım var, kendi metoduna erişti
köpek.sesCikar()  // kalıtım var, kendi metoduna erişti


//Protocol (Interface)

protocol MyProtocol{
    
    var degisken:Int{ get set }
    
    func metod1()
    
    func metod2() -> String
}

class ClassA : MyProtocol{
    
    var degisken: Int = 10
    
    func metod1() {
        print("metod 1 calisti")
    }
    
    func metod2() -> String {
        return "metod 2 calisti"
    }
    
}

let classA = ClassA()
print(classA.degisken)

classA.metod1()

print(classA.metod2())




//Extension
//belirlenen class'a özellik ekleme, genişletme

extension Int {
    func carp(sayi:Int?) -> Int{
        return sayi! * self
    }
}

print(5.carp(sayi: 6))


//Closure
let ifade = {
    print("closure calisti")
}

ifade()

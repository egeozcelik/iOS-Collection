import UIKit

var numaralar = [10, 20, 30] // 0. -> 10, 1. -> 20, 2. -> 30

var meyveler = [String]() //empty arr

// Append data
meyveler.append("Elma")//0. Index
meyveler.append("Muz") //1. Index
meyveler.append("Kiraz") //2. Index

print(meyveler)

//Update
meyveler[0]  = "Yeni Elma"

print(meyveler)

//Insert data
meyveler.insert("Portakal", at: 1) //shift the rest
print(meyveler)

//Read
let meyve = meyveler[2]
print(meyve)


print("Boş control : \(meyveler.isEmpty)")
print("Boyut :  \(meyveler.count)")
print("İlk Eleman :  \(meyveler.first!)")
print("Son Eleman :  \(meyveler.last!)")
print("İçeriyor mu : \(meyveler.contains("Muzx"))")
print("Index Bulma : \(meyveler.firstIndex(of: "Muz")!)") //istenilen değer kaçıncı indexte

for meyve in meyveler{//foreach loop
    print("Sonuç : \(meyve)")
}

for (indeks, meyve) in meyveler.enumerated(){// (kotlin) withIndex()
    print("\(indeks). -> \(meyve)")
}

meyveler.remove(at: 1)
print(meyveler)

//Nesne Tabanli

class Yemekler {
    var id: Int?
    var ad: String?
    var fiyat: Int?
    var puan: Double?
    
    
    init(id:Int, ad:String, fiyat:Int, puan:Double){
        self.id = id
        self.ad = ad
        self.fiyat = fiyat
        self.puan = puan
    }
}

var y1 = Yemekler(id: 1, ad: "Köfte", fiyat: 80, puan: 4.6)
var y2 = Yemekler(id: 2, ad: "Ayran", fiyat: 30, puan: 3.8)
var y3 = Yemekler(id: 3, ad: "Tramisu", fiyat: 75, puan: 4.3)

var yemeklerListesi = [Yemekler]()
yemeklerListesi.append(y1)
yemeklerListesi.append(y2)
yemeklerListesi.append(y3)

for y in yemeklerListesi{
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}


//Filtreleme
print("------filtreleme1------------")
var f1 = yemeklerListesi.filter({ $0.fiyat! > 50  && $0.fiyat! < 80})
for y in f1 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

print("------filtreleme2------------")
var f2 = yemeklerListesi.filter({ $0.ad!.contains("an")})
for y in f2 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

//Sıralama - Sorting

print("------Fiyat:Azalan------------")
var s1 = yemeklerListesi.sorted(by: {$0.fiyat! > $1.fiyat!})//descending : DESC
for y in s1 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

print("------Fiyat:Artan------------")
var s2 = yemeklerListesi.sorted(by: {$0.fiyat! < $1.fiyat!})//ascending : ASC
for y in s2 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

print("------Puan:Azalan------------")
var s3 = yemeklerListesi.sorted(by: {$0.puan! > $1.puan!})//descending : DESC
for y in s3 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

print("------Puan:Artan------------")
var s4 = yemeklerListesi.sorted(by: {$0.puan! < $1.puan!})//ascending : ASC
for y in s4 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

print("------Alfabetik:Azalan------------")
var s5 = yemeklerListesi.sorted(by: {$0.ad! > $1.ad!})//descending : DESC
for y in s5 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

print("------Alfabetik:Artan------------")
var s6 = yemeklerListesi.sorted(by: {$0.ad! < $1.ad!})//ascending : ASC
for y in s6 {
    print("Id : \(y.id!) - Ad : \(y.ad!) - Fiyat : \(y.fiyat!) - Puan : \(y.puan!) ")
}

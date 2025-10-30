import UIKit

//Set - HashSet

var meyveler = Set<String>()
    
//Veri Ekleme
meyveler.insert("Elma")
meyveler.insert("Portakal")
meyveler.insert("Muz")

print(meyveler)

meyveler.insert("Amasya Elma")

print("Boyut : \(meyveler.count)")

print("Boş Kontrol : \(meyveler.isEmpty)")

for meyve in meyveler {
    print("Sonuç : \(meyve)")
}

for (indeks, meyve) in meyveler.enumerated(){
    print("\(indeks). -> \(meyve) ")
}

meyveler.remove("Muz")
print(meyveler)


var indeks = meyveler.firstIndex(of: "Elma")
meyveler.remove(at: indeks!)
print(meyveler)

meyveler.removeAll()
print(meyveler)

//Dictionary - Map - HashMap
//Json veri modeli


var iller = [Int:String]()
iller[16] = "BURSA"
iller[34] = "ISTANBUL"
iller[35] = "IZMIR"

print(iller)

//Veri Güncelleme
iller[16] = "Yeni Bursa"
print(iller)

//Veri Okuma
let il = iller[34]
print(il!)


for (anahtar, deger) in iller{
    print("\(anahtar)  ->  \(deger)")
}


iller.removeValue(forKey: 16)
print(iller)


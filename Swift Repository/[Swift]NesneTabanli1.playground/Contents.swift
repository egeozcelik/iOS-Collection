import UIKit


//Class Oluşturma
class Urunler {
    var renk:String?
    var fiyat:Int?
    var stokDurum:Bool?
    
    init(){//boş constructor - initializer
        print("boş constructor")
    }
    init(renk:String, fiyat:Int, stokDurum: Bool){//dolu constructor - initializer
        self.renk = renk//shadowing, gölgeleme(this)
        self.fiyat = fiyat
        self.stokDurum = stokDurum
        print("dolu constructor")
    }
    
    func satisBaslat(){//Side Effect
        stokDurum = true
    }
    func satisDurdur(){
        stokDurum = false
    }
    
    func bilgiAl(){
        print("--------------------------------")
        print("Rengi       : \(renk!) ")
        print("Fiyatı      : \(fiyat!)")
        print("Stok durumu : \(stokDurum!)")
        
    }
    
    func fiyatArtis(kacFiyat:Int){
        fiyat! += kacFiyat
    }
    func fiyatAzalis(kacFiyat:Int){
        fiyat! -= kacFiyat
    }
}


//Nesne Oluşturma
let tv = Urunler(renk: "Beyaz", fiyat: 8000, stokDurum: true)
tv.bilgiAl()

//Değer atama
tv.renk = "Siyah"
tv.fiyat = 30000
tv.stokDurum = true
tv.bilgiAl()


//Deger Okuma
tv.bilgiAl()
tv.satisDurdur()
tv.bilgiAl()
tv.fiyatArtis(kacFiyat: 1000)
tv.bilgiAl()
tv.fiyatAzalis(kacFiyat: 2000)
tv.bilgiAl()

let saat = Urunler()
saat.renk = "Metalik"
saat.fiyat = 5000
saat.stokDurum = false

saat.bilgiAl()
saat.fiyatArtis(kacFiyat: 2000)
saat.bilgiAl()
saat.fiyatAzalis(kacFiyat: 4000)
saat.bilgiAl()


//Lec 3

class Fonksiyonlar{
    //void : Geri Dönüş Değeri olmayan
    func selamla1(){
        let sonuc = "Merhaba Ahmet"
        print(sonuc)
    }
    
    //return : geri dönüş değeri olan
    func selamla2() -> String {
        
        let sonuc = "Merhaba Ahmet"
        return sonuc
        
    }
    
    //parametre alma
    func selamla3(isim:String){
        let sonuc = "Merhaba \(isim)"
        print(sonuc)
    }
    
    func toplama(sayi1:Int, sayi2:Int) -> Int{
        let toplam = sayi1 + sayi2
        return toplam
    }
    
    //Overloading, aynı isimli fonksiyonu tekrar tekrar kullanabilme
    //ya parametrelerin tipini değiştirerek ya da yanına başka bir parametre ekleyerek bunun önüne geçilebilir.
    func carpma(sayi1:Int, sayi2:Int){
        print("Çarpma: \(sayi1*sayi2)")
    }
    func carpma(sayi1:Double, sayi2:Double){
        print("Çarpma: \(sayi1*sayi2)")
    }
    func carpma(sayi1:Int, sayi2:Int, isim:String){
        print("Çarpma: \(sayi1*sayi2) , İşlemi yapan : \(isim)")
    }
}

let f = Fonksiyonlar()

f.selamla1()


let gelenSonuc = f.selamla2()
print(gelenSonuc)

f.selamla3(isim: "Zeynep")

let gelenToplam = f.toplama(sayi1: 10, sayi2: 20)
print(gelenToplam)


f.carpma(sayi1: 3, sayi2: 5, isim: "Ege")



class ASinifi{
    static var x = 10
    
    static func metod(){
        print("Metod Çalıştı")
    }
}
let a = ASinifi()
//print(a.x)
//a.metod()

//Virtual Object - sanal nesne - nameless object - isimsiz nesne

//print(ASinifi().x)//1.Nesne
//ASinifi().metod()//2.Nesne
//Her kullanımında yeni bir nesne oluşturur

print(ASinifi.x)
ASinifi.metod()


//static = companion object olarak geçer(kotlin dilinde)

//Enum - Enumeration
enum KonserveBoyut{
    case kucuk
    case orta
    case buyuk
}

func ucretHesapla(boyut:KonserveBoyut, adet:Int){
    switch boyut {
    case .kucuk : print("Ücret: \(adet * 18 )")
    case .orta : print("Ücret: \(adet * 25 )")
    case .buyuk : print("Ücret: \(adet * 47 )")
    }
}


ucretHesapla(boyut: .orta, adet: 10)


//Composition, bütün dillerde olan bir yaklaşım, foreign key(bir class içerisinde başka bir classtan nesne barındırma)

class Kategoriler{
    var kategori_id:Int?
    var kategori_ad:String?
    
    init(kategori_id:Int, kategori_ad:String)
    {
        self.kategori_id = kategori_id
        self.kategori_ad = kategori_ad
        
        
    }
}
class Yonetmenler{
    var yonetmen_id:Int?
    var yonetmen_ad:String?
    
    init(yonetmen_id:Int, yonetmen_ad:String)
    {
        self.yonetmen_ad = yonetmen_ad
        self.yonetmen_id = yonetmen_id
    }
}



class Filmler{
    var film_id:Int?
    var film_ad:String?
    var film_yil:Int?
    
    var kategori:Kategoriler?//Composition
    var yonetmen:Yonetmenler?//Composition
    
    init(film_id:Int, film_ad:String, film_yil:Int, kategori:Kategoriler, yonetmen:Yonetmenler){
        self.film_id = film_id
        self.film_ad = film_ad
        self.film_yil = film_yil
        self.kategori = kategori
        self.yonetmen = yonetmen
    }
}

let k1 = Kategoriler(kategori_id: 1, kategori_ad: "Dram")
let k2 = Kategoriler(kategori_id: 2, kategori_ad: "Bilim Kurgu")

let y1 = Yonetmenler(yonetmen_id: 1, yonetmen_ad: "Quentin Tarantino")
let y2 = Yonetmenler(yonetmen_id: 2, yonetmen_ad: "Christopher Nolan")


let f1 = Filmler(film_id: 1, film_ad: "Django", film_yil: 2013, kategori: k1 , yonetmen: y1)


print("Film Adı:         :\(f1.film_ad!)")
print("Film Yılı:        :\(f1.film_yil!)")
print("Film kategori:    :\(f1.kategori!.kategori_ad!)")
print("Film Yönetmeni    :\(f1.yonetmen!.yonetmen_ad!)")





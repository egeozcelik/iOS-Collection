import UIKit

//Guard = if'in tersi
// Fonksiyon içinde çalışması lazım

func kisiTanima1(ad:String){
    if ad == "Ahmet"{
        print("Merhaba Ahmet")
    }else{
        print("Tanınmayan Kisi")
    }
}
kisiTanima1(ad: "Ahmet")



func kisiTanima2(ad:String){
    guard ad == "Ahmet" else {
        print("Tanınmayan Kişi")
        return //Fonksiyonun çalışmasını durdurur
    }
    print("Merhaba Ahmet")
}

kisiTanima2(ad: "Ahmet")






//Try Catch


//1. Compile Error
  
    //let sayi = 10
    //sayi = 50



//2. Runtime Error : Exception
enum Hatalar:Error{
    case sifiraBolunmeHatasi
}

func bolme(sayi1:Int, sayi2:Int) throws -> Int{
  
    if sayi2 == 0{
        throw Hatalar.sifiraBolunmeHatasi
    }
    return sayi1/sayi2
}




do{
    let sonuc = try bolme(sayi1: 10, sayi2: 0)
    print(sonuc)
}catch{
    print("Hata olustu")
}


do{
    let sonuc = try bolme(sayi1: 10, sayi2: 0)
    print(sonuc)
}catch Hatalar.sifiraBolunmeHatasi{  //hatam sıfıra bölünme hatasıysa fırlat
    print("Hata olustu")
}

let sonuc1 = try? bolme(sayi1: 10, sayi2: 0) //hata varsa sonuc1 nil olacak

if let temp = sonuc1{
    print(temp)
}else{
    print("Hata oluştu")
}

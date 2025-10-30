import UIKit

//Karşılaştırma Operatörleri
var a = 40
var b = 50

var x = 90
var y = 80
print("a == b:  \(a==b)")
print("a != b:  \(a != b)")
print("a > b:  \(a > b)")
print("a <= b:  \(a >= b)")
print("a >= b:  \(a <= b)")
print("a < b:  \(a <= b)")


print("a > b || x > y \(a > b || x > y)")  //OR(VEYA), false||false  : false, diğer durumlarda her taman true
print("a > b && x > y \(a > b && x > y)")  //AND(VE), true&&true  : true, diğer durumlarda her taman false


//if kullanımı

var yas = 17
var isim = "Ahmet"

if yas >= 18{
    print("Reşitsiniz")
}else{
    print("Reşit değilsiniz")
}


if isim == "Ahmet"{
    print("merhaba Ahmet!")
}else if isim == "Mehmet"{
    print("merhaba Mehmet!")
}else{
    print("tanınmayan kişi")
}


var ka = "admin"
var s = 123456

if ka == "admin" && s == 123456{
    print("Hoşgeldiniz")
}else{
    print("Hatalı Giriş")
}

var sonuc = 10

if sonuc == 10 || sonuc == 20{
    print("sonuç 10 veya 20dir")
}else{
    print("sonuç 10 veya 20 değildir")
}

var z = 10
var t = 20


z == t ? print("eşittir") : print("Eşit değildir")// Ternary

//Switch
//Kotlin(When)

var gun = 3

switch gun{
    case 1 : print("Pazartesi")
    case 2: print("Salı")
    case 3: print("Çarşamba")
    case 4: print("Perşembe")
    case 5: print("Cuma")
    case 6: print("Cumartesi")
    case 7: print("Pazar")
    default: print("Böyle bir gün yok")
}

//Loop - Döngüler

//1,2,3
for k in 1...3{//kotlin 1..3 - foreach
    print("Döngü 1 : \(k)")
}


//10 ile 20 arasında 5er artış
for i in stride(from: 10, through: 20, by: 5){
    print("Döngü 2: \(i)")
}

//20 ile 10 arasında 5er azalıl
for i in stride(from: 20, through: 10, by: -5){
    print("Döngü 3: \(i)")
}
//strideThrough da son değeri de kapsar. "]" gibi
//strideTo son değeri kapsamaz. ")" gibi


//1,2,3
var sayac = 1
while sayac < 4{
    print("Döngü 4: \(sayac)")
    //sayac = sayac + 1
    sayac += 1
}

//break and contiune
for i in 1...5{
    
    
    if i == 3{
        break
    }
    print("Döngü 5: \(i)")
}

for i in 1...5{
    
    
    if i == 3{
        continue
    }
    print("Döngü 6: \(i)")
}

import UIKit

//Optional - Nullable - Null Safety
//nil, null, NaN

//?, !

var str = "Hello"
//Tanımlama
var mesaj:String? //var mesaj:String? = nil
mesaj = "Merhaba"


if mesaj != nil{
    print(mesaj!)//unwrapped, eğer ! koymazsam çıktım Optional("Merhaba") şeklinde olacaktı
}else{
    print("mesaj nildir.")
}

//Optional Binding = if let yapısı
let temp = mesaj //nil ise false, nil değilse true. Yani mesaj'ın içi doluysa temp'e aktar eğer mesajın içi boşsa hata ver
if let temp = mesaj{
    print(temp)//otomatik olarak unwrapped olacak. iOS'in sağladığı kolaylık
}else{
    print("mesaj nildir.")
}


// let yerine var da kullanabilirim, bunda bir hata olmaz.
// var değişkeninin değerini sonradan değiştirebilirim fakat let değişkenine değer atadıktan sonra değiştiremem
if var temp = mesaj{
    print(temp)
    temp = "nasılsın"
    print(temp)
}else{
    print("mesaj nildir.")
}


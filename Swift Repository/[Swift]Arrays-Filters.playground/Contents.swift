import UIKit

//Arrays

//declerations
var numaralar = [10, 20, 30] // 0. -> 10, 1. -> 20, 2. -> 30

var meyveler = [String]() //empty array

//Append data
meyveler.append("Elma")   // 0. Index
meyveler.append("Muz")    // 1. Index
meyveler.append("Kiraz")  // 2. Index

print(meyveler)

//Update data
meyveler[0] = "Yeni Elma"  //Replaced with the 0. Index element (elma -> yeni elma)

print(meyveler)

//Insert data
meyveler.insert("Portakal", at: 1) //shifts the rest
print(meyveler)

let meyve = meyveler[2]
print(meyve)


print("Boş Kontrol : \(meyveler.isEmpty)")
print("Boyut : \(meyveler.count)")
print("İlk eleman : \(meyveler.first!)")
print("Son Eleman : \(meyveler.last!)")
print("İçeriyor mu? \(meyveler.contains("Muz"))")
print("Index bulma : \(meyveler.firstIndex(of: "Muz")!)") //at which Index is the desired value

for meyve in meyveler{//foreach loop
    print("Sonuç : \(meyve)")
}


for (indeks, meyve) in meyveler.enumerated(){
    print("\(indeks). -> \(meyve) ")
}


//Remove data
meyveler.remove(at: 1)
print(meyveler)



// Object Oriented


class Foods {
    var id:Int?
    var Name:String?
    var Price:Int?
    var Points: Double?
    
    init(id:Int, name:String, price:Int, points:Double) {
        self.id = id
        self.Name = name
        self.Price = price
        self.Points = points
    }
}

var food1 = Foods(id: 1, name: "Köfte", price: 80, points: 4.6)
var food2 = Foods(id: 2, name: "Ayran", price: 30, points: 3.7)
var food3 = Foods(id: 3, name: "Tiramisu", price: 50, points: 4.3)

var foodList = [Foods]()
foodList.append(food1)
foodList.append(food2)
foodList.append(food3)

for food in foodList{
    print("Id: \(food.id!), Name: \(food.Name!), Price: \(food.Price!),  Pts: \(food.Points!)")
}
print("")


//Filtering

print("------filter 1------")
var filter1 = foodList.filter({$0.Price! > 40 && $0.Price! < 75})
for food1 in filter1{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")

print("------filter 2------")
var filter2 = foodList.filter({$0.Name!.contains("Ayr")})
for food1 in filter2{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")

//Sorting


print("------Price: DESC ------")
var sort1 = foodList.sorted(by: {$0.Price! > $1.Price!})
for food1 in sort1{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")

print("------Price: ASC ------")
var sort2 = foodList.sorted(by: {$0.Price! < $1.Price!})
for food1 in sort2{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")

print("------Point: DESC ------")
var sort3 = foodList.sorted(by: {$0.Points! > $1.Points!})
for food1 in sort3{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")

print("------Point: ASC ------")
var sort4 = foodList.sorted(by: {$0.Points! < $1.Points!})
for food1 in sort4{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")


print("------Alphabetic: ASC ------")
var sort5 = foodList.sorted(by: {$0.Name! > $1.Name!})
for food1 in sort5{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")


print("------Alphabetic: DESC ------")
var sort6 = foodList.sorted(by: {$0.Name! < $1.Name!})
for food1 in sort6{
    print("Id: \(food1.id!), Name: \(food1.Name!), Price: \(food1.Price!),  Pts: \(food1.Points!)")
}
print("")


//Set - HashSet

var meyveler2 = Set<String>()

//Veri Ekleme
meyveler2.insert("Elma")
meyveler2.insert("Portakal")
meyveler2.insert("Muz")
//Randomly Indexed

print(meyveler2)

meyveler2.insert("Amasya Elması")
print(meyveler2)


print("Item count : \(meyveler2.count)")

print("Is Empty? \(meyveler2.isEmpty)")

for meyve2 in meyveler2{
    print("Value : \(meyve2)")
}

for (indeks, meyve) in meyveler2.enumerated(){
    print("\(indeks). -> \(meyve)")
}


meyveler2.remove("Muz") //According to given string value
print(meyveler2)

var indeks = meyveler2.firstIndex(of: "Elma") //return index number of desired item
meyveler2.remove(at: indeks!)//according to index no

//Dictionary - Map - Hashmap
//Json data model

var cities = [Int:String]() //2 parameters entered, first one acts like index, second one is value

cities[48] = "Muğla"
cities[26] = "Eskişehir"
cities[35] = "İzmir"

print(cities)


//Update data

cities[48] = "Yeni Muğla"
print(cities)

let city = cities[26]
print(city!)


for (key, value) in cities{
    print("\(key).-> \(value)")
}

cities.removeValue(forKey: 16)
print(cities)


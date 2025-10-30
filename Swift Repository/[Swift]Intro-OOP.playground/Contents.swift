import UIKit

//OPTIONAL

var isim:String? // Defining its optional(nullable) with using "?"

print(isim) //değer atamadığım için nil çıktısını verdi
isim = "ege"
print(isim) // It shows me the value due to assign it. But it shows me the way Optional("ege") because I dont use "!"
print(isim!) // Making it unwrapped with using !. I told myself to programa that this is a string value.

//optional binding
//We try to understand if the data is nil or not (if(deger != null))
var method:String?
method = "Optional binding"

if method != nil{
    print(method)
}else{
    print("isim nildir")
}



// optional binding with if let structure
let temp = method//if the name is nil, it turn false. if it doesnt nil, assigns to temp
if let temp = method{
    print(temp)// dont need to use "!"
}else{
    print("isim nildir")
}


//OBJECT ORIENTED
class User{
    var Id:Int?
    var Name:String?
    var Age:Int?
    var isActive:Bool?
}

let student1 = User() // not using "new" keyword
student1.Id = 1
student1.Name = "Ege"
student1.Age = 24
student1.isActive = true

print("student 1 name is \(student1.Name!) and his age \(student1.Age!) . Also his activity is \(student1.isActive!) ")


class FunctionalUser{
    var Id:Int?
    var Name:String?
    var Age:Int?
    var isActive:Bool!
    
    init(){
        print("Empty Constructor")
    }
    
    func printData(){
        print(" //////////\\\\\\\\\\")
        print(" Name      : \(Name!)")
        print(" Age       : \(Age!)")
        print(" isActive  : \(isActive!)")
    }
    
    func IncreaseAge(){
        Age! += 1
    }
    func DecreaseAge(){
        Age! -= 1
    }
}

var student2 = FunctionalUser()
student2.Id = 2
student2.Name = "Elif"
student2.Age = 25
student2.isActive = false

student2.printData()
student2.IncreaseAge()
student2.printData()
student2.DecreaseAge()
student2.printData()

class InitUser {
    var Id:Int?
    var Name:String?
    var Age:Int?
    var isActive:Bool?
    
    init(){
        print("This is an initilaizer of InitUser")
    }
    
    init(Id:Int, Name:String, Age:Int, isActive:Bool){
        self.Id = Id
        self.Name = Name
        self.Age = Age
        self.isActive = isActive
    }
    
    func printData(){
        print(" //////////\\\\\\\\\\")
        print(" Id        : \(Id!)")
        print(" Name      : \(Name!)")
        print(" Age       : \(Age!)")
        print(" isActive  : \(isActive!)")
    }
}

var student3 = InitUser(Id: 3, Name: "Ahmet", Age: 25, isActive: true)
student3.printData()
var student4 = InitUser()



//Inheritance

//A class transfers its property to another class
//superclass : üst sınıf
//subclass : alt sınıf

//A class can have single inheritance, we can provide multiple inheritance with interface (protocol)

class Person{
    var Age:Int?
    var Name:String?
    init(Age:Int, Name:String){
        self.Age = Age
        self.Name = Name
    }
}

class Student : Person{
    var grade:Int?
    
    init(grade:Int, Age:Int, Name:String){
        self.grade = grade
        super.init(Age: Age, Name:Name) // using super keyword
    }
}

class Teacher : Person{
    var Branch:String?
    
    init(Branch:String, Age:Int, Name:String) {
        self.Branch = Branch
        super.init(Age:Age, Name:Name)
    }
}

var teacher1 = Teacher(Branch: "Physics", Age: 34, Name: "Cahit")
var student5 = Student(grade: 3, Age: 19, Name: "Mehmet")

print("Name of the Teacher: \(teacher1.Name!), Age: \(teacher1.Age!), Branch: \(teacher1.Branch!)")
print("Name of the Student: \(student5.Name!), Age: \(student5.Age!), Grade: \(student5.grade!)")


//Upcasting Student --> Person

let student6 = Student(grade: 4, Age: 20, Name: "Veli") as Person

//Downcasting  Person --> Student

let person1 = Person(Age: 25, Name: "Ahmet") as? Student

//if you use ? and error occurs Student = nil
//if you use ! and error occurs application fails


//Type Control
if person1 is Student{
    print("This object generated from student")
}else{
    print("This object does not generated from student")
}

//Override Usage

class Animal{
    func sounds(){
        print("No Sound")
    }
}
class Mammal :Animal{}

class Cat:Mammal{
    override func sounds() {
        print("meow!")
    }
}

class Dog:Mammal{
    override func sounds() {
        print("Hav Hav!")
    }
}

let animal = Animal()
let mammal = Mammal()
let cat = Cat()
let dog = Dog()

animal.sounds() //No inheritance, uses own method
mammal.sounds() //inherited, uses upperclass method
cat.sounds()    //inherited, uses own method
dog.sounds()    //inherited, uses own method


//Protocols - Interfaces

protocol MyProtocol{
    var variable1:Int{get set}
    
    func func1()
    
    func func2() -> String
}

class MyClass : MyProtocol{
    var variable1: Int = 10
    
    func func1() {
        print("function 1 working")
    }
    
    func func2() -> String {
        return "function 2 working"
    }
}

let myclass = MyClass()

print(myclass.variable1)
myclass.func1()
print(myclass.func2())


//Extensions
//Adding a function to defined class, made it extend

extension Int{//Integer class
    func multiplyWith(num:Int?) -> Int{
        return num! * self
    }
}

print(5.multiplyWith(num: 4))

extension String{
    func printString(){
        print(self)
    }
}

"Ege".printString()


//Closures

let closureSample = {
    print("closure working")
}

closureSample()

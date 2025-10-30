import UIKit


class homework2{
   
    
    func question1(celsius:Double) -> Double{
        let fahrenhiet = (celsius * 1.8) + 32
        return fahrenhiet
    }

    func question2(edge1:Int, edge2:Int){
        let perimeter = (edge1 + edge2) * 2
        print("perimeter of the rectangular is :\(perimeter)")
    }
    
    func question3(value:Int) -> Int{
        var factorial = 1
        
        if(value > 0 ){
            for i in 1...value{
                factorial *= i
            }
        }
        return factorial
    }
    
    func question4(word:String){
        var counter = 0
        
        for letter in word{
            if letter == "a"{
                counter += 1
            }
        }
        print("There are \(counter)  letter in \(word) word")
    }
    
    func question5(edge:Int) -> Int{
            return (edge-2) * 180
    }
    
    func question6(day:Int) -> Int{
        let totalSalary:Int?
        
        if((day*8) > 160){
            totalSalary = (day*8*10) + ((day*8)-160)*20 //160 saat normal çalışma ücreti + 160'ın üzerindeki mesai ücreti
        }else{
            totalSalary = day*8*10 //160 saate kadarki normal çalışma ücreti
        }
        
        return totalSalary!;
    }
    
    func question7(limitGB:Int)-> Int{
        if limitGB < 50{
            return 100 //50GB' a kadar 100tl
        }else{
            return 100 + ((limitGB - 50)*4) //50Gb sonrasında her GB = 4tl
        }
    }
    
}

let f = homework2()


//1.
print("Question 1: ")
var celcius = 120.0
let fahrenhiet = f.question1(celsius: celcius)
print("\(celcius) celcius -> \(fahrenhiet) fahrenhiet.")
print("- - - - - - - - -")
print("")

//2.
print("Question 2: ")
f.question2(edge1: 3, edge2: 5)
print("- - - - - - - - -")
print("")

//3.
print("Question 3: ")
var number = 7
let fac = f.question3(value: number)
print("\(number) factorial is: \(fac)")
print("- - - - - - - - -")
print("")

//4
print("Question 4:")
f.question4(word: "TechCareer iOS Development Bootcamp")
print("- - - - - - - - -")
print("")


//5
print("Question 5:")
var edges = 4
let result = f.question5(edge: edges)
print("sum of the interior angles of a \(edges)-sided shape is: \(result) degrees")
print("- - - - - - - - -")
print("")

//6
print("Question 6:")
var days = 21
let salary = f.question6(day: days)
print("Net salary of \(days) days work: \(salary) tl")
print("- - - - - - - - -")
print("")

//7
print("Question 7:")
var limit = 75
print("total bill of the \(limit) GB limited Internet is \(f.question7(limitGB: limit)) tl")
print("- - - - - - - - -")
print("")


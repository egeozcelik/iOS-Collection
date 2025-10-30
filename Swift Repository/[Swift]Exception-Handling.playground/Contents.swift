import UIKit

//Guard = Opposite of if
//Has to work in a function

func userLogin1(name:String){
    if name == "Ege"{
        print("Hello Ege")
    }else{
        print("Unknown User")
    }
}
userLogin1(name: "Ege")

func userLogin2(name:String){
    guard name == "Ege" else{
        print("Unknown User")
        return //stops the func
    }
    
    print("Hello Ege")
}

userLogin2(name: "Ege")


//Try Catch

//1. Compiler Error

    //Let number = 10
    //number = 20

//2. Runtime Error : Exception

enum Errors:Error{//Inherited from systems error class
    case dividedByZero
}

func division(num1:Int, num2:Int) throws -> Int{
    //Throws stands for error
    if num2 == 0{
        throw Errors.dividedByZero
    }
    return num1/num2
}


do{
    let result = try division(num1: 10, num2: 0)
    print(result)
}catch{
    print("Error occured")
}

let result2 = try? division(num1: 10, num2: 0) //If there is an error, result2 will be nil

if let temp = result2{
    print(temp)
}else{
    print("Error Occured")
}

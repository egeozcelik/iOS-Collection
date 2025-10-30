//
//  ViewController.swift
//  Calculator
//
//  Created by Ege Özçelik on 19.09.2023.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var labelCalculation: UILabel!
    @IBOutlet weak var labelSonuc: UILabel!
    @IBOutlet weak var labelInvalid: UILabel!
    
    
    var calculationStr:String! = ""
    var numberToCalculate = [Int]()
    var numberValue:Int?
    var result = 0
    var numberArray = [Int]()
    var numbersInExpression = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    func expression(str:String){
        calculationStr.append(str)
        showExpression(str: calculationStr)
    }
    func showExpression(str:String){
        labelCalculation.text = str
    }
    
    func Calculate(str:String){
        
    }
    
    
    
    @IBAction func btn1(_ sender: Any) {
        expression(str: String("1"))
    }
    
    @IBAction func btn2(_ sender: Any) {
        expression(str: String("2"))
    }
    
    @IBAction func btn3(_ sender: Any) {
        expression(str: String("3"))
    }
    
    @IBAction func btn4(_ sender: Any) {
        expression(str: String("4"))
    }
    
    @IBAction func btn5(_ sender: Any) {
        expression(str: String("5"))
    }
    
    @IBAction func btn6(_ sender: Any) {
        expression(str: String("6"))
    }
    
    @IBAction func btn7(_ sender: Any) {
        expression(str: String("7"))
    }
    
    @IBAction func btn8(_ sender: Any) {
        expression(str: String("8"))
    }
    
    @IBAction func btn9(_ sender: Any) {
        expression(str: String("9"))
    }
    
    
    @IBAction func btn0(_ sender: Any) {
        expression(str: String("0"))
    }
    
    
    @IBAction func btnTopla(_ sender: Any) {
        expression(str: String("+"))
    }
    
    @IBAction func btnEsittir(_ sender: Any) {
        if calculationStr.first == "+" || calculationStr.last == "+"{
            calculationStr.first == "+" ? (labelInvalid.text = "Invalid Operation: (?)" + calculationStr)
            : (labelInvalid.text = "Invalid Operation: " + calculationStr + "(?)")
            
            labelSonuc.text = ""
        }else{
            labelInvalid.text = ""
            detectNumbersInArray()
            addNumbers()
        }
        clearResults()
    }
    
    
    @IBAction func btnC(_ sender: Any) {
        labelSonuc.text = ""
        labelInvalid.text = ""
        clearResults()
    }
    
    func detectNumbersInArray(){
        
        for element in calculationStr!{
            if element != "+"{
                numbersInExpression.append(String(element))
                var _numberValue = numbersInExpression.joined(separator: "")
                numberValue = Int(_numberValue)
            }
            else{
                numberArray.append(numberValue!)
                numbersInExpression = []
            }
        }
        numberArray.append(numberValue!)
    }
    func addNumbers(){
        if !calculationStr.isEmpty{
            for addedNumbers in numberArray{
                result = result + addedNumbers
            }
            labelSonuc.text = String(result)
        }else{
            labelInvalid.text = "Enter an operation"
            labelSonuc.text = ""
        }
    }
    
    func clearResults(){
        numberValue = 0
        result = 0
        numberArray = []
        numbersInExpression = []
        calculationStr = ""
        showExpression(str: calculationStr)
        
    }
    
    
    
    
    
}


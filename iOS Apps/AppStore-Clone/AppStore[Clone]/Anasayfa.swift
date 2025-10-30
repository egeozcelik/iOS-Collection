//
//  ViewController.swift
//  AppStore[Clone]
//
//  Created by Ege Özçelik on 30.09.2023.
//

import UIKit

class Anasayfa: UIViewController {

    
    @IBOutlet weak var gameTableView: UITableView!
    
    
    var gameList = [Game]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let g1 = Game(game_id: 1, name: "Minion Rush: Running Game", description: "Endless run with the Minions", picture: "minionrush-logo")
        let g2 = Game(game_id: 2, name: "CarX Street", description: "Open world street racing", picture: "carXstreet-logo")
        let g3 = Game(game_id: 3, name: "Project Makeover", description: "Makeover Puzzle Game ", picture: "projectMakeover-logo")
        
        gameList.append(g1)
        gameList.append(g2)
        gameList.append(g3)
        
        gameTableView.delegate = self
        gameTableView.dataSource = self
    }


    
}

extension Anasayfa : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameCell") as! GameCell
        
        let game = gameList[indexPath.row]
        
        cell.imageViewGame.image = UIImage(named: game.picture!)
        cell.labelGameName.text = game.name
        cell.labelGameDesc.text = game.description
        
        return cell
    }
    
    
}


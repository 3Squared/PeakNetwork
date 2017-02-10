//
//  ViewController.swift
//  NetworkExamples
//
//  Created by Sam Oakley on 01/02/2017.
//  Copyright © 2017 3Squared. All rights reserved.
//

import UIKit
import THRNetwork

class ViewController: UITableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.imageView?.contentMode = .scaleAspectFill
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = "Row \(indexPath.row + 1)"
        cell.imageView?.image = #imageLiteral(resourceName: "Placeholder")
        cell.imageView?.setImage(URL(string: "https://unsplash.it/100/100/?random=\(((indexPath.row / 5) * 5) + 50)/")!, animation: AnimationOptions(duration: 0.3, options: .transitionCrossDissolve))
    }
}


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
    
    var searchResults: [SearchResult] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }
    
    @IBAction func refresh() {
        self.searchResults = []
        
        WebService.shared.search(for: "Hello World!") { [unowned self] result in
            DispatchQueue.main.async {
                switch (result) {
                case .success((let searchResults, _)):
                    self.searchResults = searchResults
                case .failure(ServerError.error(code: .internalServerError, response: _)):
                    let alert = UIAlertController(title: "Custom Error", message: "A server error occurred.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                case .failure(let error):
                    let alert = UIAlertController(title: "Generic Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.imageView?.contentMode = .scaleAspectFill
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        
        cell.textLabel?.text = result.description
        cell.detailTextLabel?.text = result.url.absoluteString

        cell.imageView?.image = #imageLiteral(resourceName: "Placeholder")
        cell.imageView?.setImage(result.imageURL)
    }
}


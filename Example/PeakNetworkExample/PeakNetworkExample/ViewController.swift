//
//  ViewController.swift
//  PeakNetworkExamples
//
//  Created by Sam Oakley on 01/02/2017.
//  Copyright © 2017 3Squared. All rights reserved.
//

import UIKit
import PeakNetwork

class ViewController: UITableViewController {
    
    let api = ExampleAPI()
    
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
        
        api.search("Hello World!").enqueue { result in
            DispatchQueue.main.async {
                switch (result) {
                case .success(let response):
                    self.searchResults = response.parsed
                case .failure(ServerError.error(code: .internalServerError, data: _, response: _)):
                    let alert = UIAlertController(title: "Internal Server Error", message: "A server error occurred.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
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

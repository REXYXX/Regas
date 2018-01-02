//
//  musicRepertoryTableViewController.swift
//  Regas
//
//  Created by apple on 2017/12/10.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import os.log


class MusicRepertoryTableViewController: UITableViewController {
    
    var musicName: String!
    var selectMusic: Music!
    var musics: Array<Music>? = nil
    //搜索栏
    var musicSearchController = UISearchController()
    var searchArray:[Music] = [Music](){
        didSet {
            self.tableView.reloadData()
        }
    }
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musics = MUSICS
        
        //搜索栏
        self.musicSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.hidesNavigationBarDuringPresentation = false
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.searchBarStyle = .minimal
            controller.searchBar.sizeToFit()
            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.musicSearchController.isActive {
            return self.searchArray.count
        } else {
            return self.musics!.count;
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MusicRepertoryTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MusicRepertoryTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MusicRepertoryTableViewCell.")
        }

        if self.musicSearchController.isActive {
            
            let music = self.searchArray[indexPath.row]
            cell.musicInformation.text = music.musicName
        } else {
            
            let music = musics![indexPath.row]
            cell.musicInformation.text = music.musicName;
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        musicName = musics![indexPath.row].musicName
        selectMusic = musics![indexPath.row]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === selectButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
}

extension MusicRepertoryTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if(self.musics!.count == 0){
            return
        }
        self.searchArray = self.musics!.filter { (music) -> Bool in
            return music.musicName!.uppercased().contains(searchController.searchBar.text!.uppercased())
        }
    }
}

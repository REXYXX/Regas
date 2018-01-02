//
//  VideoRepertoryTableViewController.swift
//  Regas
//
//  Created by apple on 2017/12/26.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import os.log

class VideoRepertoryTableViewController: UITableViewController {
    
    var selectVideo: Video?
    //搜索栏
    var musicSearchController = UISearchController()
    var searchArray:[Video] = [Video](){
        didSet {
            self.tableView.reloadData()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }

    // MARK: - Table view data source
    @IBOutlet weak var selectButton: UIBarButtonItem!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.musicSearchController.isActive {
            return self.searchArray.count
        } else {
            return VIDEOS!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "VideoRepertoryTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VideoRepertoryTableViewCell  else {
            fatalError("The dequeued cell is not an instance of VideoRepertoryTableViewCell.")
        }
        // Fetches the appropriate meal for the data source layout.
        if self.musicSearchController.isActive {
            let video = self.searchArray[indexPath.row]
            cell.videoInfomation.text = video.videoName!
        } else {
            let video = VIDEOS![indexPath.row]
            cell.videoInfomation.text = video.videoName!
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        selectVideo = VIDEOS![indexPath.row]
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
extension VideoRepertoryTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if(VIDEOS!.count == 0){
            return
        }
        self.searchArray = VIDEOS!.filter { (video) -> Bool in
            return video.videoName!.uppercased().contains(searchController.searchBar.text!.uppercased())
        }
    }
}

//
//  VideoTableViewController.swift
//  Regas
//
//  Created by apple on 2017/12/9.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import MobileCoreServices


class VideoTableViewController: UITableViewController {

    var Videos: Array<Video>?
    let NotifyVideo = NSNotification.Name("NotifyVideo")
    //搜索栏
    var musicSearchController = UISearchController()
    var searchArray:[Video] = [Video](){
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getVideos()
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(didMsgRecv(notification:)), name: NotifyVideo, object: nil)
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
 
        if self.musicSearchController.isActive {
            return self.searchArray.count
        } else {
            return self.Videos!.count;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "VideoTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? VideoTableViewCell  else {
            fatalError("The dequeued cell is not an instance of VideoTableViewCell.")
        }
        if self.musicSearchController.isActive {
            
            let video = self.searchArray[indexPath.row]
            cell.VideoInformation.text = video.videoName!
        } else {
            
            let video = Videos![indexPath.row]
            cell.VideoInformation.text = video.videoName
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let moviePlayer = AVPlayer(url: self.Videos![indexPath.row].videoURL!)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = moviePlayer
        self.present(playerViewController, animated: true){
            playerViewController.player!.play()
        }
        
        moviePlayer.play()
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let action0 = UITableViewRowAction(style: UITableViewRowActionStyle.default,title:"删除"){ (action, indexPath) -> Void in
            self.Videos?.remove(at: indexPath.row)
            VIDEOS?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        return [action0]
    }
    
    @IBAction func addVideo(_ sender: UIBarButtonItem) {
        self.startMediaBrowserFromViewController(self, usingDelegate:self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
    }
    
    func startMediaBrowserFromViewController(_ viewController: UIViewController, usingDelegate delegate: UINavigationControllerDelegate & UIImagePickerControllerDelegate) -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            return false
        }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .savedPhotosAlbum
        mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        
        present(mediaUI, animated: true, completion: nil)
        return true
        
    }
    
    private func getVideos(){
        if VIDEOS == nil {
            VIDEOS = Array<Video>()
            Videos = VIDEOS
        }
    }

}

// MARK: - UIImagePickerControllerDelegate

extension VideoTableViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        dismiss(animated: true)
        {
            if mediaType == kUTTypeMovie {
                
                let video: Video = Video()
                if let i = VIDEOS?.count {
                    video.videoName = "video" + String(i)
                } else {
                    video.videoName = "video0"
                }
                
                video.videoURL = (info[UIImagePickerControllerMediaURL] as! URL)
                VIDEOS?.append(video)
                let newIndexPath = IndexPath(row: self.Videos!.count, section: 0)
                self.Videos!.append(video)
                self.tableView.insertRows(at: [newIndexPath], with: .bottom)
                self.tableView.reloadData()
            }
 
        }
    }
    
    @objc func didMsgRecv(notification: NSNotification){
        if VIDEOS == nil {
            return ;
        }
        else if self.Videos!.count < VIDEOS!.count {
            
            for i in self.Videos!.count...VIDEOS!.count-1 {
                
                let newIndexPath = IndexPath(row: Videos!.count, section: 0)
                Videos!.append(VIDEOS![i])
                self.tableView.insertRows(at: [newIndexPath], with: .bottom)
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension VideoTableViewController: UINavigationControllerDelegate {
}

extension VideoTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if(self.Videos!.count == 0){
            return
        }
        self.searchArray = self.Videos!.filter { (video) -> Bool in
            return video.videoName!.uppercased().contains(searchController.searchBar.text!.uppercased())
        }
    }
}

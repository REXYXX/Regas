//
//  ViewController.swift
//  Regas
//
//  Created by apple on 2017/12/7.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class MusicViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet weak var MusicTableView: UITableView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var musicProgress: UIProgressView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var totalTime: UILabel!
    
    let NotifyMusic = NSNotification.Name("NotifyMusic")
    let NotifyTransMusic = NSNotification.Name("NotifyTransMusic")
    let NotifyMergeMusic = NSNotification.Name("NotifyMergeMusic")
    
    var avAudioPlayer:AVAudioPlayer!
    var isSelect: Bool!
    var playMusic: Bool!
    var timer: Timer!
    var musics: Array<Music>? = nil

    //搜索栏
    var musicSearchController = UISearchController()
    var searchArray:[Music] = [Music](){
        didSet {
            self.MusicTableView.reloadData()
        }
    }
    @IBAction func listPlayButton(_ sender: Any) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.getMusic()
        
        MusicTableView.delegate = self
        MusicTableView.dataSource = self
        
        //搜索栏
        self.musicSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.hidesNavigationBarDuringPresentation = false
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.searchBarStyle = .minimal
            controller.searchBar.sizeToFit()
            self.MusicTableView.tableHeaderView = controller.searchBar
            return controller
        })()
        
        isSelect = false
        playMusic = false
        
        playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        currentTime.text = "0:0"
        totalTime.text = "0:0"
        musicProgress.progress = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(didMsgRecv(notification:)), name: NotifyMusic, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didMsgRecv(notification:)), name: NotifyTransMusic, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didMsgRecv(notification:)), name: NotifyMergeMusic, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.musicSearchController.isActive {
            return self.searchArray.count
        } else {
            return self.musics!.count;
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MusicTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MusicTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MusicTableViewCell.")
        }
        
        if self.musicSearchController.isActive {
            
            let music = self.searchArray[indexPath.row]
            cell.MusicInfo.text = music.musicName
        } else {
            
            let music = musics![indexPath.row]
            cell.MusicInfo.text = music.musicName;
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        initTimer()
        initAVAudioPlayer(url: self.musics![indexPath.row].musicURL!)
        self.avAudioPlayer.play()
        
        playButton.setImage(#imageLiteral(resourceName: "stop"), for: .normal)
        
        isSelect = true
        playMusic = true
        self.totalTime.text = timeFormatted(totalSeconds: Int(avAudioPlayer.duration))
        
        self.timer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.showMusicProgress), userInfo: nil, repeats: true)
        
 //       tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let action0 = UITableViewRowAction(style: UITableViewRowActionStyle.default,title:"删除"){ (action, indexPath) -> Void in
            self.musics?.remove(at: indexPath.row)
            MUSICS?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        /*
        let action1 = UITableViewRowAction(style: UITableViewRowActionStyle.default,title:"编辑"){ (action, indexPath) -> Void in
            
        }*/
        return [action0]
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func initAVAudioPlayer(url: URL){
        
        do{
            try self.avAudioPlayer = AVAudioPlayer(contentsOf: url)
        }
        catch{
            
        }
            
    }
    
    @IBAction func playMusic(_ sender: Any) {
        if isSelect {
            if playMusic {
                avAudioPlayer.pause()
                playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                playMusic = false
            } else {
                playButton.setImage(#imageLiteral(resourceName: "stop"), for: .normal)
                avAudioPlayer.play()
                playMusic = true
            }
        }
        else {
            
        }
    }
    
    @objc func showMusicProgress(){
        self.musicProgress.progress = Float(avAudioPlayer.currentTime/avAudioPlayer.duration)
        self.currentTime.text = timeFormatted(totalSeconds: Int(avAudioPlayer.currentTime))
        
    }
    
    func timeFormatted(totalSeconds:Int)->String{
        let seconds : String = String(totalSeconds % 60)
        let minutes :String = String((totalSeconds / 60) % 60);
        //获取字符串长度
        return minutes+":"+seconds
    }
    
    func initTimer(){
        if self.timer != nil {
            self.timer.invalidate();
            self.timer = nil;
        }
    }
    
    private func getMusic(){
        
        if self.musics == nil{
            var musicArryList=Array<Music>()
            var fileArry:[String]?
            
            let path=Bundle.main.path(forResource:"music", ofType: nil)
            do{
                try fileArry=FileManager.default.contentsOfDirectory(atPath: path!)
            }
            catch{
                print("error")
            }
            for n in fileArry! {
                let singlePath=path!+"/"+n
                
                let musicModel:Music = Music()
                
                musicModel.musicName = n;
                
                musicModel.musicURL=URL.init(fileURLWithPath: singlePath)

                musicArryList.append(musicModel)
                
            }
            
            musics=musicArryList
            
            if MUSICS == nil {
                MUSICS = musics
            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        if MUSICS == nil {
            return ;
        }
        else if self.musics!.count < MUSICS!.count {
            
            for i in self.musics!.count...MUSICS!.count-1 {
                
                let newIndexPath = IndexPath(row: musics!.count, section: 0)
                musics!.append(MUSICS![i])
                MusicTableView.insertRows(at: [newIndexPath], with: .bottom)
                MusicTableView.reloadData()
            }
        }
    }
    
    @objc func didMsgRecv(notification: NSNotification){
        if MUSICS == nil {
            return ;
        }
        else if self.musics!.count < MUSICS!.count {
           
            for i in self.musics!.count...MUSICS!.count-1 {
                
                let newIndexPath = IndexPath(row: musics!.count, section: 0)
                musics!.append(MUSICS![i])
                MusicTableView.insertRows(at: [newIndexPath], with: .bottom)
                MusicTableView.reloadData()
            }
        }
    }
    
    @IBAction func unwindToMusicView(sender: UIStoryboardSegue) {
        if let sourceTableViewController = sender.source as? LocalMusicTableViewController, let music = sourceTableViewController.selectMusic {
            
            let newIndexPath = IndexPath(row: musics!.count, section: 0)
            self.musics?.append(music)
            self.MusicTableView.insertRows(at: [newIndexPath], with: .bottom)
            self.MusicTableView.reloadData()
    
        }
    }
}

extension MusicViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if(self.musics!.count == 0){
            return
        }
        self.searchArray = self.musics!.filter { (music) -> Bool in
            return music.musicName!.uppercased().contains(searchController.searchBar.text!.uppercased())
        }
    }
}

class LocalMusicTableViewController: UITableViewController {
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

    @IBOutlet weak var confirmButton: UIBarButtonItem!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {

        musics = Array<Music>()
        let everything = MPMediaQuery()
        let itemsFromGenericQuery = everything.items
        for song in itemsFromGenericQuery! {
            let music = Music()
            let songTitle = song.value(forProperty: MPMediaItemPropertyTitle)
            let songUrl = song.value(forProperty: MPMediaItemPropertyAssetURL)
            music.musicName = songTitle as? String
            music.musicURL = songUrl as? URL
        }
        
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
        
        super.viewDidLoad()
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
        let cellIdentifier = "LocalMusicTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LocalMusicTableViewCell  else {
            fatalError("The dequeued cell is not an instance of LocalMusicTableViewCell.")
        }
        
        if self.musicSearchController.isActive {
            
            let music = self.searchArray[indexPath.row]
            cell.musicInfo.text = music.musicName
        } else {
            
            let music = musics![indexPath.row]
            cell.musicInfo.text = music.musicName;
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
        guard let button = sender as? UIBarButtonItem, button === confirmButton else {
            os_log("The confirm button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
    
}

class LocalMusicTableViewCell: UITableViewCell{
    
    @IBOutlet weak var musicInfo: UILabel!
}

extension LocalMusicTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if(self.musics!.count == 0){
            return
        }
        self.searchArray = self.musics!.filter { (music) -> Bool in
            return music.musicName!.uppercased().contains(searchController.searchBar.text!.uppercased())
        }
    }
}


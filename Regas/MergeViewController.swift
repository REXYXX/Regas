//
//  mergeViewController.swift
//  Regas
//
//  Created by apple on 2017/12/27.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit

class MergeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var musics: Array<Music>?
    var mergeMusic: Music?
    var musicName: String?
    let NotifyMergeMusic = NSNotification.Name("NotifyMergeMusic")
    
    var avAudioPlayer:AVAudioPlayer!
    var nextMusic: Int!
    var isPlay: Bool?
    var entireTime: Float?
    var beforeTime: Float?
    
    @IBOutlet weak var playSlider: UISlider!
    @IBOutlet weak var musicListView: UITableView!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var totalTime: UILabel!
    
    var timer: Timer!
    
    override func viewDidLoad() {
        self.getMusic()
        super.viewDidLoad()
        musics = Array<Music>()
        musicListView.delegate = self
        musicListView.dataSource = self
        
        playSlider.maximumTrackTintColor = UIColor.white
        playSlider.minimumTrackTintColor = UIColor.lightGray
        playSlider.maximumValue = 1
        playSlider.minimumValue = 0
        playSlider.value = 0
        
        //
        entireTime = 0
        beforeTime = 0
        isPlay = false
        nextMusic = 0
        //
        self.currentTime.text = "00:00"
        self.totalTime.text = "00:00"
        
        playSlider.addTarget(self, action: #selector(sliderDidChange(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if musics?.count == 0 {
            return
        }
        initTimer()
        do {
            try self.avAudioPlayer = AVAudioPlayer(contentsOf: musics![indexPath.row].musicURL!)
        } catch {
            
        }
        isPlay = true
        self.avAudioPlayer.play()
        self.playButton.setTitle("暂停", for: .normal)
        self.timer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.showMusicProgress), userInfo: nil, repeats: true)
        
        self.beforeTime = 0
        if indexPath.row == 0 {
            self.beforeTime = 0
        }
        else {
            for i in 0...indexPath.row-1{
                let originalAsset:AVURLAsset = AVURLAsset(url:musics![i].musicURL!)
                beforeTime = beforeTime! + Float(originalAsset.duration.seconds)
            }
        }
        if indexPath.row == (musics?.count)! - 1 {
            nextMusic = 0
        } else {
            nextMusic = indexPath.row + 1
        }
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musics!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "MergeTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MergeTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MergeTableViewCell.")
        }
        // Fetches the appropriate meal for the data source layout
        cell.musicNameLable.text = self.musics![indexPath.row].musicName
        return cell
    }
    
    @IBAction func unwindToMusicList(sender: UIStoryboardSegue) {
        if let sourceTableViewController = sender.source as? MergeMusicTableViewController, let music = sourceTableViewController.selectMusic {
            
            let newIndexPath = IndexPath(row: musics!.count, section: 0)
            self.musics?.append(music)
            musicListView.insertRows(at: [newIndexPath], with: .bottom)
            musicListView.reloadData()
            
            let originalAsset:AVURLAsset = AVURLAsset(url: music.musicURL!)
            
            self.entireTime = self.entireTime! + Float(originalAsset.duration.seconds)
            playSlider.maximumValue = self.entireTime!
            self.totalTime.text = self.timeFormatted(totalSeconds: Int(self.entireTime!))
        }
        if let sourceViewController = sender.source as? mergeMusicFileSaveController {
            
            let musicname = sourceViewController.musicName
            self.musicName = musicname! + ".m4a"
            self.merge()
        }
        if let sourceTableViewController = sender.source as? LocalMusicShowTableViewController, let music = sourceTableViewController.selectMusic {
            
            let newIndexPath = IndexPath(row: musics!.count, section: 0)
            self.musics?.append(music)
            musicListView.insertRows(at: [newIndexPath], with: .bottom)
            musicListView.reloadData()
            
            let originalAsset:AVURLAsset = AVURLAsset(url: music.musicURL!)
            
            self.entireTime = self.entireTime! + Float(originalAsset.duration.seconds)
            playSlider.maximumValue = self.entireTime!
            self.totalTime.text = self.timeFormatted(totalSeconds: Int(self.entireTime!))
        }
    }
    private func merge(){
        if self.musics?.count == 0{
            return
        }
        
        let composition:AVMutableComposition = AVMutableComposition()
        let appendedAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        let originalAsset:AVURLAsset = AVURLAsset(url: musics![0].musicURL!)
        let assetTrack1 =  originalAsset.tracks(withMediaType: AVMediaType.audio)[0]
        let timeRange1 = CMTimeRangeMake(kCMTimeZero, originalAsset.duration)
        try! appendedAudioTrack.insertTimeRange(timeRange1, of: assetTrack1, at:kCMTimeZero)
        var insertTime = originalAsset.duration
        
        for i in 1...musics!.count-1 {
            let anotherAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            let newAsset:AVURLAsset = AVURLAsset(url: musics![i].musicURL!)
            let timeRange = CMTimeRangeMake(kCMTimeZero, newAsset.duration)

            try! anotherAudioTrack.insertTimeRange(timeRange, of: assetTrack1, at:insertTime)
            
            insertTime = insertTime + newAsset.duration
        }
        
         let exportSession:AVAssetExportSession = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetAppleM4A)!
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = (documentDirectory as NSString).appendingPathComponent(self.musicName!)
        let url = URL(fileURLWithPath: filePath)
        exportSession.outputURL = url
        exportSession.outputFileType = AVFileType.m4a
        exportSession.shouldOptimizeForNetworkUse = true
        
        let mergemusic = Music()
        mergemusic.musicName = self.musicName!
        mergemusic.musicURL = url
        self.mergeMusic = mergemusic
        
        for music in MUSICS! {
            if music.musicName == self.mergeMusic?.musicName {
                music.musicName = self.mergeMusic?.musicName
                music.musicURL = self.mergeMusic?.musicURL
                return
            }
        }
        MUSICS!.append(self.mergeMusic!)
    
        NotificationCenter.default.post(name: NotifyMergeMusic, object: self)
    
        exportSession.exportAsynchronously() {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Compele", message: "Music has been saved", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func getMusic(){
        if MUSICS == nil{
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
            
            MUSICS = musicArryList
        }
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
    
    @IBAction func playMusic(_ sender: Any) {
        
        if self.avAudioPlayer != nil {
            if !isPlay! {
                self.avAudioPlayer.play()
                playButton.setTitle("暂停", for: .normal)
                isPlay = true
            } else {
                self.avAudioPlayer.pause()
                playButton.setTitle("播放", for: .normal)
                isPlay = false
            }
        } else {
            
        }
    }
    @IBOutlet weak var playButton: UIButton!
    
    @objc func sliderDidChange(_ slider:UISlider) {
     
       if slider == self.playSlider {
            
            if self.musics!.count > 0 && playSlider.value < playSlider.maximumValue{
                var temp = playSlider.value
                var i: Int = 0
                beforeTime = 0
                for music in musics! {
                    let originalAsset:AVURLAsset = AVURLAsset(url:music.musicURL!)
                    if temp - Float(originalAsset.duration.seconds) >= 0 {
                        temp = temp - Float(originalAsset.duration.seconds)
                        beforeTime = beforeTime! + Float(originalAsset.duration.seconds)
                        i = i + 1
                    } else {
                        break
                    }
                }
                if i == musics!.count - 1{
                    nextMusic = 0;
                } else {
                    nextMusic = i+1
                }
               try! avAudioPlayer = AVAudioPlayer(contentsOf: musics![i].musicURL!)
               avAudioPlayer.currentTime = TimeInterval(temp)
               avAudioPlayer.play()
               self.isPlay = true
               self.playButton.setTitle("暂停", for: .normal)
            }
        }
    }
    
    @objc func showMusicProgress(){
        if avAudioPlayer == nil {
            return
        }
        self.playSlider.value = self.beforeTime! + Float(self.avAudioPlayer.currentTime)
        self.currentTime.text = self.timeFormatted(totalSeconds: Int(self.playSlider.value))
        if self.playSlider.value - self.beforeTime! > Float(self.avAudioPlayer.duration)-0.1{
            if nextMusic == 0 {
                beforeTime = 0
                try! avAudioPlayer = AVAudioPlayer(contentsOf: musics![0].musicURL!)
                avAudioPlayer.play()
                if nextMusic == musics!.count - 1 {
                    nextMusic = 0
                }
                else {
                    nextMusic = nextMusic + 1
                }
                self.playSlider.value = self.beforeTime! + Float(self.avAudioPlayer.currentTime)
                self.currentTime.text = self.timeFormatted(totalSeconds: Int(self.playSlider.value))
            }
            else {
                beforeTime = beforeTime! + Float(avAudioPlayer.duration)
                try! avAudioPlayer = AVAudioPlayer(contentsOf: musics![nextMusic].musicURL!)
                avAudioPlayer.play()
                if nextMusic == musics!.count - 1 {
                    nextMusic = 0
                }
                else {
                    nextMusic = nextMusic + 1
                }
            }
        }
    }
    
}

class MergeMusicTableViewController: UITableViewController {
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
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        
        musics = MUSICS
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
        let cellIdentifier = "MergeMusicTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MergeMusicTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MergeMusicTableViewCell.")
        }
        // Fetches the appropriate meal for the data source layout.
        if self.musicSearchController.isActive {
            
            let music = self.searchArray[indexPath.row]
            cell.musicName.text = music.musicName
        } else {
            
            let music = musics![indexPath.row]
            cell.musicName.text = music.musicName;
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
extension MergeMusicTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if(self.musics!.count == 0){
            return
        }
        self.searchArray = self.musics!.filter { (music) -> Bool in
            return music.musicName!.uppercased().contains(searchController.searchBar.text!.uppercased())
        }
    }
}

class MergeMusicTableViewCell: UITableViewCell{
    
    @IBOutlet weak var musicName: UILabel!
}

class mergeMusicFileSaveController: UIViewController, UITextFieldDelegate{
    
    var musicName: String?
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    @IBOutlet weak var musicNameText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musicNameText.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        musicName = musicNameText.text
        
        guard let button = sender as? UIBarButtonItem, button === confirmButton , musicName != nil else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
}



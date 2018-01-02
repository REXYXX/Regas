//
//  VideoCutViewController.swift
//  Regas
//
//  Created by apple on 2017/12/30.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia
import os.log

class VideoCutViewController: UIViewController, UINavigationControllerDelegate{
    
    var videoForCut: Video? = nil
    var videoAfterCut: Video? = nil
    var transMusic: Music? = nil
    var asset: AVAsset!
    var exportSession: AVAssetExportSession!
    let NotifyVideo = NSNotification.Name("NotifyVideo")
    let NotifyTransMusic = NSNotification.Name("NotifyTransMusic")
    var videoName: String!
    var musicName: String!
    
    var timer: Timer!
    
    @IBOutlet weak var selectTime: UILabel!
    @IBOutlet weak var entireTime: UILabel!
    @IBOutlet weak var beginTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var endTimeSlider: UISlider!
    @IBOutlet weak var beginTimeSlider: UISlider!
    @IBOutlet weak var playSlider: UISlider!
    
    @IBOutlet weak var playerView: videoView!
    var playerItem: AVPlayerItem!
    var avplayer: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isPlay: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getVideo()
        self.getMusic()
        
        //init lable
        self.selectTime.text = "00:00"
        self.entireTime.text = "00:00"
        self.beginTime.text = "00:00"
        self.endTime.text = "00:00"
        
        endTimeSlider.maximumTrackTintColor = UIColor.lightGray
        endTimeSlider.minimumTrackTintColor = UIColor.white
        beginTimeSlider.maximumTrackTintColor = UIColor.white
        beginTimeSlider.minimumTrackTintColor = UIColor.lightGray
        playSlider.maximumTrackTintColor = UIColor.white
        playSlider.minimumTrackTintColor = UIColor.lightGray
        
        beginTimeSlider.setThumbImage(UIImage(named: "cut"), for: .normal)
        endTimeSlider.setThumbImage(UIImage(named: "cut"), for: .normal)
        
        beginTimeSlider.maximumValue = 1
        beginTimeSlider.minimumValue = 0
        beginTimeSlider.value = 0
        endTimeSlider.maximumValue = 1
        endTimeSlider.minimumValue = 0
        endTimeSlider.value = 1
        playSlider.maximumValue = 1
        playSlider.minimumValue = 0
        playSlider.value = 0
        
        
        //slider事件
        beginTimeSlider.addTarget(self, action: #selector(sliderDidChange(_:)), for: UIControlEvents.valueChanged)
        endTimeSlider.addTarget(self, action: #selector(sliderDidChange(_:)), for: UIControlEvents.valueChanged)
        playSlider.addTarget(self, action: #selector(sliderDidChange(_:)), for: UIControlEvents.valueChanged)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func videoCut(){
        if self.videoForCut == nil {
            return
        }
        let fileURL: URL = videoForCut!.videoURL!
        let startTime: Float64 = Float64(self.beginTimeSlider.value)
        let endTime: Float64 = Float64(self.endTimeSlider.value)
        
        asset = AVAsset(url: fileURL)
        
        let start: CMTime = CMTimeMakeWithSeconds(startTime, asset.duration.timescale)
        let duration: CMTime = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale)
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = (documentDirectory as NSString).appendingPathComponent(self.videoName)
        let url = URL(fileURLWithPath: filePath)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        
        exportSession.outputURL = url
        exportSession.timeRange = CMTimeRange(start: start, duration: duration)
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        let afterVideo: Video = Video()
        afterVideo.videoName = self.videoName
        afterVideo.videoURL = url
        
        self.videoAfterCut = afterVideo
        
        exportSession.exportAsynchronously() {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Compele", message: "Video has been saved", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func videoTransToMusic(){
        if self.videoForCut == nil {
            return
        }
        
        let fileURL: URL = videoForCut!.videoURL!
        let startTime: Float64 = Float64(self.beginTimeSlider.value)
        let endTime: Float64 = Float64(self.endTimeSlider.value)
        
        asset = AVAsset(url: fileURL)
        
        let start: CMTime = CMTimeMakeWithSeconds(startTime, asset.duration.timescale)
        let duration: CMTime = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale)
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = (documentDirectory as NSString).appendingPathComponent(self.musicName)
        let url = URL(fileURLWithPath: filePath)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return }
        
        exportSession.outputURL = url
        exportSession.timeRange = CMTimeRange(start: start, duration: duration)
        exportSession.outputFileType = AVFileType.m4a
        exportSession.shouldOptimizeForNetworkUse = true
        
        let afterMusic: Music = Music()
        afterMusic.musicName = self.musicName
        afterMusic.musicURL = url
        
        self.transMusic = afterMusic
        
        exportSession.exportAsynchronously() {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Compele", message: "Music has been saved", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func getVideo(){
        
        if VIDEOS == nil {
            VIDEOS = Array<Video>()
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
    @IBAction func unwindToVideoCut(sender: UIStoryboardSegue) {
 
        if let sourceTableViewController = sender.source as? VideoRepertoryTableViewController, let video = sourceTableViewController.selectVideo {
            videoForCut = video
            
            playerItem = AVPlayerItem(url: videoForCut!.videoURL!)
            self.avplayer = AVPlayer(playerItem: playerItem)
            self.avplayer.automaticallyWaitsToMinimizeStalling = false
            self.playerLayer = AVPlayerLayer(player: avplayer)
            self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            self.playerLayer.contentsScale = UIScreen.main.scale
            
            self.playerView.playerLayer = self.playerLayer
            self.playerView.layer.insertSublayer(self.playerLayer, at: 0)
            
            let duration: CMTime = (self.playerLayer.player?.currentItem?.asset.duration)!

            self.beginTimeSlider.maximumValue = Float(duration.seconds)
            self.endTimeSlider.maximumValue = Float(duration.seconds)
            self.endTimeSlider.value = self.endTimeSlider.maximumValue
            self.playSlider.maximumValue = Float(duration.seconds)
            
            self.entireTime.text = self.timeFormatted(totalSeconds: Int(duration.seconds))
            self.endTime.text = self.timeFormatted(totalSeconds: Int(duration.seconds))
            
            initTimer()
            self.timer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.showMusicProgress), userInfo: nil, repeats: true)
            
        }
        
        if let sourceViewController = sender.source as? videoFileSaveController, avplayer != nil {
            
            let videoname = sourceViewController.videoName
            self.videoName = videoname! + ".mov"
            
            self.videoCut()
            
            if self.videoAfterCut != nil && VIDEOS != nil{
                
                for video in VIDEOS! {
                    if video.videoName == videoAfterCut?.videoName {
                        video.videoName = videoAfterCut?.videoName
                        video.videoURL = videoAfterCut?.videoURL
                        return
                    }
                }
                VIDEOS!.append(videoAfterCut!)
            }
            NotificationCenter.default.post(name: NotifyVideo, object: self)
            
        }
        
        if let sourceViewController = sender.source as? musicFileSaveController, avplayer != nil {
            
            let musicname = sourceViewController.musicName
            self.musicName = musicname! + ".mov"
            
            self.videoTransToMusic()
            
            if self.transMusic != nil && MUSICS != nil{
                
                for music in MUSICS! {
                    if music.musicName == self.transMusic!.musicName {
                        music.musicName = self.transMusic!.musicName
                        music.musicURL = self.transMusic!.musicURL
                        return
                    }
                }
                MUSICS!.append(self.transMusic!)
            }
            NotificationCenter.default.post(name: NotifyTransMusic, object: self)
            
        }
    }
    
    @objc func sliderDidChange(_ slider:UISlider) {
        
        if slider == self.beginTimeSlider{
            
            if slider.value > self.endTimeSlider.value{
                slider.value = self.endTimeSlider.value
            }
            
            self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
            self.beginTime.text = timeFormatted(totalSeconds: Int(self.beginTimeSlider.value))
        }
        else if slider == self.endTimeSlider {
            
            if slider.value < self.beginTimeSlider.value {
                slider.value = self.beginTimeSlider.value
            }
            
            self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
            self.endTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value))
        }
        else if slider == self.playSlider {

            if self.playerView.playerLayer != nil && playSlider.value < playSlider.maximumValue{
                
                let start: CMTime = CMTimeMake(Int64(playSlider.value), 1)
                self.playerView.playerLayer?.player?.seek(to: start, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
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
    
    @objc func showMusicProgress(){
        let current: CMTime = (self.playerLayer.player?.currentTime())!
        let currentSeconds: Float = Float(CMTimeGetSeconds(current))
        playSlider.value = currentSeconds
        
        if playSlider.maximumValue == playSlider.value {
            self.playButton.setTitle("播放视频", for: .normal)
            self.isPlay = false
            self.playSlider.value = 0
        }
        
        if playSlider.value > self.endTimeSlider.value {
            self.playSlider.value = self.beginTimeSlider.value
            let start: CMTime = CMTimeMake(Int64(beginTimeSlider.value), 1)
            self.playerView.playerLayer?.player?.seek(to: start, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }

    }
    
    @IBAction func playVideo(_ sender: Any) {
        if self.avplayer != nil {
            if !isPlay {
                self.avplayer.play()
                playButton.setTitle("暂停音乐", for: .normal)
                isPlay = true
            } else {
                self.avplayer.pause()
                playButton.setTitle("播放音乐", for: .normal)
                isPlay = false
            }
        } else {
            
        }
    }
    
    @IBAction func addLocalMusic(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            return
        }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .savedPhotosAlbum
        mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        
        present(mediaUI, animated: true, completion: nil)
    }
    
    @IBAction func addBeginTime(_ sender: Any) {
        
        if avplayer == nil {
            return
        }
        if self.beginTimeSlider.value + 0.1 > self.beginTimeSlider.maximumValue {
            self.beginTimeSlider.value = self.beginTimeSlider.maximumValue
        } else {
            self.beginTimeSlider.value += 0.1
        }
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.beginTime.text = timeFormatted(totalSeconds: Int(self.beginTimeSlider.value))
    }
    @IBAction func subBeginTime(_ sender: Any) {
        if avplayer == nil {
            return
        }
        
        if self.beginTimeSlider.value - 0.1 < self.beginTimeSlider.minimumValue {
            self.beginTimeSlider.value = self.beginTimeSlider.minimumValue
        } else {
            self.beginTimeSlider.value -= 0.1
        }
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.beginTime.text = timeFormatted(totalSeconds: Int(self.beginTimeSlider.value))
        
    }
    @IBAction func addEndTime(_ sender: Any) {
        if avplayer == nil {
            return
        }
        
        if self.endTimeSlider.value + 0.1 > self.endTimeSlider.maximumValue {
            self.endTimeSlider.value = self.endTimeSlider.maximumValue
        } else {
            self.endTimeSlider.value += 0.1
        }
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.endTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value))

    }
    @IBAction func subEndTime(_ sender: Any) {
        if avplayer == nil {
            return
        }
        
        if self.endTimeSlider.value - 0.1 < self.endTimeSlider.minimumValue {
            self.endTimeSlider.value = self.endTimeSlider.minimumValue
        } else {
            self.endTimeSlider.value -= 0.1
        }
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.endTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value))

    }
    
}

extension VideoCutViewController: UIImagePickerControllerDelegate {
    
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
                
                self.videoForCut = video
                
                self.playerItem = AVPlayerItem(url: self.self.videoForCut!.videoURL!)
                self.avplayer = AVPlayer(playerItem: self.playerItem)
                self.avplayer.automaticallyWaitsToMinimizeStalling = false
                self.playerLayer = AVPlayerLayer(player: self.avplayer)
                self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                self.playerLayer.contentsScale = UIScreen.main.scale
                
                self.playerView.playerLayer = self.playerLayer
                self.playerView.layer.insertSublayer(self.playerLayer, at: 0)
                
                let duration: CMTime = (self.playerLayer.player?.currentItem?.asset.duration)!
                
                self.beginTimeSlider.maximumValue = Float(duration.seconds)
                self.endTimeSlider.maximumValue = Float(duration.seconds)
                self.endTimeSlider.value = self.endTimeSlider.maximumValue
                self.playSlider.maximumValue = Float(duration.seconds)
                
                self.entireTime.text = self.timeFormatted(totalSeconds: Int(duration.seconds))
                self.endTime.text = self.timeFormatted(totalSeconds: Int(duration.seconds))
                
                self.initTimer()
                self.timer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.showMusicProgress), userInfo: nil, repeats: true)
                
            }
        }
    }
}

class videoView: UIView{
    
    var playerLayer: AVPlayerLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
 
}

class videoFileSaveController: UIViewController, UITextFieldDelegate {
    
    var videoName: String!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    @IBOutlet weak var videoNameText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoNameText.delegate = self
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
        
        videoName = videoNameText.text
        
        guard let button = sender as? UIBarButtonItem, button === confirmButton , videoName != nil else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
    }
}

class musicFileSaveController: UIViewController, UITextFieldDelegate {
    var musicName: String!
    
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

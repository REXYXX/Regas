//
//  CutViewController.swift
//  Regas
//
//  Created by apple on 2017/12/10.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia
import os.log

class MusicCutViewController: UIViewController ,EZAudioFileDelegate, EZAudioPlayerDelegate{
    
    var musicForCut: Music? = nil
    var musicAfterCut: Music? = nil
    var asset: AVAsset!
    var exportSession: AVAssetExportSession!
    let NotifyMusic = NSNotification.Name("NotifyMusic")
    var avAudioPlayer:AVAudioPlayer!
    var musicName: String!
    
    var musicBeging:UIButton!
    var leftCover:UIButton!
    var rightCover:UIButton!
    var audioFile: EZAudioFile?
    var player = EZAudioPlayer()

    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var playingAudioPlot: EZAudioPlot!
    
    @IBOutlet weak var endTimeSlider: UISlider!
    @IBOutlet weak var beginTimeSlider: UISlider!
    @IBOutlet weak var playSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var selectTime: UILabel!
    @IBOutlet weak var entireTime: UILabel!
    @IBOutlet weak var beginTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    
    var timer: Timer!
    
    @IBAction func addMusicButton(_ sender: Any) {
    }
    @IBAction func playMusicButton(_ sender: Any) {
        if (self.player.audioFile) != nil {
            if !player.isPlaying {
                self.player.play()
                playButton.setTitle("暂停音乐", for: .normal)
            } else {
                self.player.pause()
                playButton.setTitle("播放音乐", for: .normal)
            }
    
        } else {
            
        }
    }
    @IBAction func saveMusicButton(_ sender: Any) {
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getMusic()
        
        player.delegate = self
        
        //plot
        self.audioPlot.backgroundColor = UIColor.lightGray
        self.audioPlot.color = UIColor.white
        self.audioPlot.plotType = EZPlotType.buffer
        self.audioPlot.shouldFill = true
        self.audioPlot.shouldMirror = true
        self.audioPlot.shouldOptimizeForRealtimePlot = false
        self.audioPlot.waveformLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.audioPlot.waveformLayer.shadowRadius = 0.0
        self.audioPlot.waveformLayer.shadowColor = UIColor.gray.cgColor
        self.audioPlot.waveformLayer.shadowOpacity = 1.0
        
        //
        self.musicBeging = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: self.audioPlot.frame.height))
        self.musicBeging.backgroundColor = UIColor.white
        self.leftCover = UIButton(frame: CGRect(x: 0, y: 0, width: 1, height: self.audioPlot.frame.height))
        self.leftCover.backgroundColor = UIColor.lightGray
        self.rightCover = UIButton(frame: CGRect(x: self.audioPlot.frame.width, y: 0, width: 1, height: self.audioPlot.frame.height))
        self.rightCover.backgroundColor = UIColor.lightGray
        audioPlot.addSubview(leftCover)
        audioPlot.addSubview(rightCover)
        audioPlot.addSubview(musicBeging)
        audioPlot.alpha = 0.5
        audioPlot.bringSubview(toFront: musicBeging)
        audioPlot.bringSubview(toFront: playSlider)
        
        self.playingAudioPlot.backgroundColor = UIColor.white
        self.playingAudioPlot.color = UIColor.lightGray
        self.playingAudioPlot.plotType        = EZPlotType.rolling
        self.playingAudioPlot.shouldFill      = true
        self.playingAudioPlot.shouldMirror    = true
        self.playingAudioPlot.gain = 2.5
        self.view.addSubview(self.playingAudioPlot)
        
        //init lable
        self.selectTime.text = "00:00"
        self.entireTime.text = "00:00"
        self.beginTime.text = "00:00"
        self.endTime.text = "00:00"
        
        endTimeSlider.maximumTrackTintColor = UIColor.lightGray
        endTimeSlider.minimumTrackTintColor = UIColor.lightGray
        beginTimeSlider.maximumTrackTintColor = UIColor.lightGray
        beginTimeSlider.minimumTrackTintColor = UIColor.lightGray
        playSlider.maximumTrackTintColor = UIColor.lightGray
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
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func sliderDidChange(_ slider:UISlider) {
        
        if slider == self.beginTimeSlider{
            
            if slider.value > self.endTimeSlider.value{
                slider.value = self.endTimeSlider.value
            }
            self.leftCover.frame = CGRect(x: 0, y: 0, width: CGFloat(beginTimeSlider.value/beginTimeSlider.maximumValue) * self.audioPlot.frame.width, height: self.audioPlot.frame.height)
            self.leftCover.reloadInputViews()
            self.audioPlot.redraw()
            
            self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
            self.beginTime.text = timeFormatted(totalSeconds: Int(self.beginTimeSlider.value))
        }
        else if slider == self.endTimeSlider {
            
            if slider.value < self.beginTimeSlider.value {
                slider.value = self.beginTimeSlider.value
            }
            self.rightCover.frame = CGRect(x: CGFloat(endTimeSlider.value/endTimeSlider.maximumValue) * self.audioPlot.frame.width, y: 0, width: CGFloat(1.0 - endTimeSlider.value/endTimeSlider.maximumValue) * self.audioPlot.frame.width, height: self.audioPlot.frame.height)
            self.rightCover.reloadInputViews()
            self.audioPlot.redraw()
            
            self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
            self.endTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value))
        }
        else if slider == self.playSlider {

            if playSlider.value > endTimeSlider.value {
                playSlider.value = endTimeSlider.value
            }
            else if playSlider.value < beginTimeSlider.value {
                playSlider.value = beginTimeSlider.value
            }
            
            self.musicBeging.frame.origin.x = CGFloat(playSlider.value/playSlider.maximumValue) * self.audioPlot.frame.width
            self.musicBeging.reloadInputViews()
            self.audioPlot.redraw()
            
            if player.audioFile != nil && playSlider.value < playSlider.maximumValue{
                
                player.currentTime = Double(playSlider.value)
            }
        }
        
    }
    
    func musicCut(){
        
        if musicForCut == nil{
            return
        }
        
        let fileURL: URL = musicForCut!.musicURL!
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
        
        self.musicAfterCut = afterMusic
        
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
    
    @IBAction func addBeginTime(_ sender: Any) {
        
        if player.audioFile == nil {
            return
        }
        if self.beginTimeSlider.value + 1.0 > self.beginTimeSlider.maximumValue {
            self.beginTimeSlider.value = self.beginTimeSlider.maximumValue
        } else {
            self.beginTimeSlider.value += 1.0
        }
        self.leftCover.frame = CGRect(x: 0, y: 0, width: CGFloat(beginTimeSlider.value/beginTimeSlider.maximumValue) * self.audioPlot.frame.width, height: self.audioPlot.frame.height)
        self.leftCover.reloadInputViews()
        self.audioPlot.redraw()
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.beginTime.text = timeFormatted(totalSeconds: Int(self.beginTimeSlider.value))
    }
    @IBAction func subBeginTime(_ sender: Any) {
        if player.audioFile == nil {
            return
        }
        if self.beginTimeSlider.value - 1.0 < self.beginTimeSlider.minimumValue {
            self.beginTimeSlider.value = self.beginTimeSlider.minimumValue
        } else {
            self.beginTimeSlider.value -= 1.0
        }
        self.leftCover.frame = CGRect(x: 0, y: 0, width: CGFloat(beginTimeSlider.value/beginTimeSlider.maximumValue) * self.audioPlot.frame.width, height: self.audioPlot.frame.height)
        self.leftCover.reloadInputViews()
        self.audioPlot.redraw()
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.beginTime.text = timeFormatted(totalSeconds: Int(self.beginTimeSlider.value))
    }
    
    @IBAction func addEndTime(_ sender: Any) {
        if player.audioFile == nil {
            return
        }
        if self.endTimeSlider.value + 1.0 > self.endTimeSlider.maximumValue {
            self.endTimeSlider.value = self.endTimeSlider.maximumValue
        } else {
            self.endTimeSlider.value += 1.0
        }
        self.rightCover.frame = CGRect(x: CGFloat(endTimeSlider.value/endTimeSlider.maximumValue) * self.audioPlot.frame.width, y: 0, width: CGFloat(1.0 - endTimeSlider.value/endTimeSlider.maximumValue) * self.audioPlot.frame.width, height: self.audioPlot.frame.height)
        self.rightCover.reloadInputViews()
        self.audioPlot.redraw()
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.endTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value))
    }
    
    @IBAction func subEndTime(_ sender: Any) {
        if player.audioFile == nil {
            return
        }
        if self.endTimeSlider.value - 1.0 < self.endTimeSlider.minimumValue {
            self.endTimeSlider.value = self.endTimeSlider.minimumValue
        } else {
            self.endTimeSlider.value -= 1.0
        }
        self.rightCover.frame = CGRect(x: CGFloat(endTimeSlider.value/endTimeSlider.maximumValue) * self.audioPlot.frame.width, y: 0, width: CGFloat(1.0 - endTimeSlider.value/endTimeSlider.maximumValue) * self.audioPlot.frame.width, height: self.audioPlot.frame.height)
        self.rightCover.reloadInputViews()
        self.audioPlot.redraw()
        
        self.selectTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value - self.beginTimeSlider.value))
        self.endTime.text = timeFormatted(totalSeconds: Int(self.endTimeSlider.value))
    }
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        if let sourceTableViewController = sender.source as? MusicRepertoryTableViewController, let music = sourceTableViewController.selectMusic {
            musicForCut = music
            audioFile = EZAudioFile(url: music.musicURL!)
            guard let waveFromData = audioFile!.getWaveformData() else{
                return
            }
            self.audioPlot.updateBuffer(waveFromData.buffers[0], withBufferSize: waveFromData.bufferSize)
            self.player.audioFile = audioFile
            self.beginTimeSlider.maximumValue = Float(player.duration)
            self.endTimeSlider.maximumValue = Float(player.duration)
            self.endTimeSlider.value = self.endTimeSlider.maximumValue
            self.playSlider.maximumValue = Float(player.duration)
            
            initTimer()
            self.timer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.showMusicProgress), userInfo: nil, repeats: true)
            self.entireTime.text = self.timeFormatted(totalSeconds: Int(player.duration))
            self.endTime.text = self.timeFormatted(totalSeconds: Int(player.duration))
            return ;
        }
        if let sourceViewController = sender.source as? saveViewController, player.audioFile != nil{
            
            let musicname = sourceViewController.musicName
            
            self.musicName = musicname! + ".m4a"
            self.musicCut()
            
            if self.musicAfterCut != nil && MUSICS != nil{
                for music in MUSICS! {
                    if music.musicName == musicAfterCut?.musicName {
                        music.musicName = musicAfterCut?.musicName
                        music.musicURL = musicAfterCut?.musicURL
                        return
                    }
                }
                MUSICS!.append(musicAfterCut!)
            }
            
            NotificationCenter.default.post(name: NotifyMusic, object: self)

        }
    }
    func wareGenerator(warefromData:UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, length:UInt32){
        self.playingAudioPlot.updateBuffer(warefromData[0], withBufferSize: length)
    }
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, in audioFile: EZAudioFile!) {
        self.playingAudioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
    }
    
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, in audioFile: EZAudioFile!) {
    }
    
    func initTimer(){
        if self.timer != nil {
            self.timer.invalidate();
            self.timer = nil;
        }
    }
    @objc func showMusicProgress(){
        self.playSlider.value = Float(self.player.currentTime)
        
        if playSlider.maximumValue == Float(self.player.currentTime) {
            self.playButton.setTitle("播放音乐", for: .normal)
            self.playSlider.value = 0
        }
        if Float(self.player.currentTime) > self.endTimeSlider.value {
            
            self.playSlider.value = self.beginTimeSlider.value
            self.player.currentTime = Double(self.beginTimeSlider.value)
        }
        self.musicBeging.frame.origin.x = CGFloat(playSlider.value/playSlider.maximumValue) * self.audioPlot.frame.width
        self.musicBeging.reloadInputViews()
        self.audioPlot.redraw()
    }
    
    
    func timeFormatted(totalSeconds:Int)->String{
        let seconds : String = String(totalSeconds % 60)
        let minutes :String = String((totalSeconds / 60) % 60);
        //获取字符串长度
        return minutes+":"+seconds
    }
}

class saveViewController: UIViewController, UITextFieldDelegate{
    
    var musicName: String!
    
    @IBOutlet weak var musicNameText: UITextField!

    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    
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

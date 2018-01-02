//
//  music.swift
//  Regas
//
//  Created by apple on 2017/12/23.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit

var MUSICS: Array<Music>? = nil

class Music : NSObject{
    
    var musicName :String?
    var musicURL :URL?
    var isActive :Bool = false
    
}

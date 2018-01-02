//
//  VideoTableViewCell.swift
//  Regas
//
//  Created by apple on 2017/12/9.
//  Copyright © 2017年 njuics. All rights reserved.
//

import UIKit
import AVFoundation

class VideoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var VideoInformation: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

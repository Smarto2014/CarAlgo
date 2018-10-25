//
//  ItemCell.swift
//  MicroLinkSample
//
//  Created by Achraf Letaief on 05/09/2018.
//  Copyright © 2018 Achraf Letaief. All rights reserved.
//

import UIKit

class ItemCell: UITableViewCell {

    @IBOutlet weak var getValueBtn: UIButton!
    @IBOutlet weak var itemValue: UILabel!
    @IBOutlet weak var itemTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

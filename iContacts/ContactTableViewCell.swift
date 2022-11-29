//
//  ContactTableViewCell.swift
//  iContacts
//
//  Created by Zhangali Pernebayev on 28.11.2022.
//

import UIKit

class ContactTableViewCell: UITableViewCell {

    static let identifier: String = "ContactTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
    }
}

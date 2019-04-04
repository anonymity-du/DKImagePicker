//
//  DKPropertySelectedCell.swift
//  DKImagePicker
//
//  Created by DU on 2019/2/12.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

protocol DKPropertySelectedCellDelegate: NSObjectProtocol {
    func propertySelectedCellSwitchValueChange(name: String, isOn: Bool)
}

class DKPropertySelectedCell: UITableViewCell {

    public weak var delegate: DKPropertySelectedCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.switchView)
        self.contentView.addSubview(self.textField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(with name: String, switchOn: Bool?) {
        self.nameLabel.text = name
        self.nameLabel.sizeToFit()
        
        if let on = switchOn {
            self.switchView.isOn = on
            self.switchView.isHidden = false
            self.textField.isHidden = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.nameLabel.x = 16
        self.nameLabel.centerY = self.contentView.height * 0.5
        self.switchView.x = self.nameLabel.right + 10
        self.switchView.centerY = self.nameLabel.centerY
        self.textField.x = self.nameLabel.right + 10
        self.textField.centerY = self.nameLabel.centerY
    }
    
    //MARK:- action
    
    @objc func switchAction() {
        self.delegate?.propertySelectedCellSwitchValueChange(name: self.nameLabel.text ?? "", isOn: self.switchView.isOn)
    }
    
    //MARK:- setter & getter
    
    private(set) lazy var nameLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private(set) lazy var switchView: UISwitch = {
        let view = UISwitch.init()
        view.isOn = false
        view.isHidden = true
        view.addTarget(self, action: #selector(switchAction), for: .valueChanged)
        return view
    }()
    
    private(set) lazy var textField: UITextField = {
        let view = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 20))
        view.borderStyle = .roundedRect
        view.backgroundColor = UIColor.white
        view.textColor = UIColor.black
        view.textAlignment = .center
        view.isHidden = true
        view.keyboardType = UIKeyboardType.numberPad
        return view
    }()
    
}

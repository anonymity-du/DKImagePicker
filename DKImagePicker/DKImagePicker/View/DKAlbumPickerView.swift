//
//  DKAlbumPickerView.swift
//  DatePlay
//
//  Created by DU on 2018/10/23.
//  Copyright © 2018 DU. All rights reserved.
//

import UIKit

protocol DKAlbumPickerViewDelegate: NSObjectProtocol {
    
    /// 选中的相簿
    ///
    /// - Parameter album: 相簿
    func didSelectAlbum(_ album: DKAlbumModel)
}

class DKAlbumPickerView: UIView {

    fileprivate var tableView: UITableView?
    fileprivate var dataSource: [DKAlbumModel] = []
    
    weak var delegate: DKAlbumPickerViewDelegate?
    
    override var frame: CGRect {
        didSet {
            self.tableView?.frame = self.bounds
        }
    }
    
    deinit {
        tableView?.delegate = nil
        tableView?.dataSource = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView = UITableView.init(frame: self.bounds, style: UITableView.Style.plain)
        tableView?.register(DKAlbumPickerTableViewCell.self, forCellReuseIdentifier:  NSStringFromClass(DKAlbumPickerTableViewCell.self))
        addSubview(tableView!)
        tableView?.delegate = self
        tableView?.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configTableViewData(with albumModels: [DKAlbumModel]) {
        self.dataSource.removeAll()
        self.dataSource.append(contentsOf: albumModels)
        self.refreshTableViewData()
    }
    
    func refreshTableViewData() {
        for albumModel in self.dataSource {
            albumModel.selectedModels = IMGInstance.configModel.selectedModels
        }
        self.tableView?.reloadData()
    }
    
    func resetScrollViewContentInset(_ offsetY: CGFloat) {
        tableView?.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0 + offsetY, right: 0)
    }
}

extension DKAlbumPickerView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DKAlbumPickerTableViewCell.self)) as! DKAlbumPickerTableViewCell
        let model: DKAlbumModel = dataSource[indexPath.row]
        
        cell.showSelectedIcon = IMGInstance.configModel.selectedAlbumModel?.name == model.name
        cell.model = model
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataSource[indexPath.row]
        if delegate != nil {
            delegate?.didSelectAlbum(model)
        }
        IMGInstance.configModel.selectedAlbumModel = model
        self.tableView?.reloadData()
    }
}

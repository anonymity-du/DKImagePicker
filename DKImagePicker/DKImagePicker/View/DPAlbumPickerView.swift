//
//  DPAlbumPickerView.swift
//  DatePlay
//
//  Created by 张昭 on 2018/10/23.
//  Copyright © 2018 AimyMusic. All rights reserved.
//

import UIKit

protocol DPAlbumPickerViewDelegate: NSObjectProtocol {
    
    /// 选中的相簿
    ///
    /// - Parameter album: 相簿
    func didSelectAlbum(_ album: DPAlbumModel)
}

class DPAlbumPickerView: UIView {

    fileprivate var tableView: UITableView?
    fileprivate var dataSource: [DPAlbumModel] = []
    
    weak var delegate: DPAlbumPickerViewDelegate?
    
    deinit {
        tableView?.delegate = nil
        tableView?.dataSource = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView = UITableView.init(frame: self.bounds, style: UITableView.Style.plain)
        tableView?.register(DPAlbumPickerTableViewCell.self, forCellReuseIdentifier:  NSStringFromClass(DPAlbumPickerTableViewCell.self))
        addSubview(tableView!)
        tableView?.delegate = self
        tableView?.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configTableViewData(with albumModels: [DPAlbumModel]) {
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

extension DPAlbumPickerView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DPAlbumPickerTableViewCell.self)) as! DPAlbumPickerTableViewCell
        let model: DPAlbumModel = dataSource[indexPath.row]
        
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

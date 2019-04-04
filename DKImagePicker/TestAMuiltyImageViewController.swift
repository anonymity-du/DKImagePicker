//
//  TestAMuiltyImageViewController.swift
//  DKImagePicker
//
//  Created by DU on 2019/4/4.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class TestAMuiltyImageViewController: UIViewController {

    private var dataSource = [DKAssetModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.imgsView)
        self.view.addSubview(self.addView)
        
        self.imgsView.y = kNaviBarHeight + 30
        self.changeImgsView()
        // Do any additional setup after loading the view.
    }
    
    @objc func addAction() {
        IMGInstance.configModel(maxImagesCount: 9 - self.dataSource.count)
        IMGInstance.configModel.allowPickingVideo = false
        IMGInstance.pushPhotoPickerVC(delegate: self)
    }
    
    private func changeImgsView() {
        for subview in self.imgsView.subviews {
            if let selectView = subview as? DKSelectedImageView {
                selectView.imgView.image = nil
            }
            subview.removeFromSuperview()
        }
        var height: CGFloat = 0
        
        let itemWidth: CGFloat = 74 * K320Scale
    
        for (index, itemModel) in self.dataSource.enumerated() {
            let itemView = DKSelectedImageView.init(frame: CGRect.init(x: 0, y: 0, width: itemWidth, height: itemWidth))
            
            itemView.assetModel = itemModel
            self.imgsView.addSubview(itemView)
            let col = index%3
            let row = index/3
            itemView.tag = 100 + index
            itemView.selectBlock = { [weak itemView] in
                print("itemview \(itemView?.tag ?? 0)")
            }
            itemView.deleteBlock = { [weak self,weak itemView] in
                let currentIndex = (itemView?.tag ?? 0) - 100
                self?.dataSource.remove(at: currentIndex)
                self?.changeImgsView()
            }
            itemView.x = (itemWidth + 4) * CGFloat(col)
            itemView.y = (itemWidth + 4) * CGFloat(row)
            height = CGFloat(itemWidth + (itemWidth + 4) * CGFloat(row))
        }
        
        self.imgsView.height = height
        if self.dataSource.count >= 9 {
            self.addView.isHidden = true
        }else {
            self.addView.isHidden = false
            let col = (self.dataSource.count)%3
            let row = (self.dataSource.count)/3
            self.addView.y = self.imgsView.y + (itemWidth + 4) * CGFloat(row)
            self.addView.x = self.imgsView.x + (itemWidth + 4) * CGFloat(col)
        }
    }
    
    //MARK:- setter & getter
    
    private lazy var imgsView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 16, y: 0, width: 74 * K320Scale * 3 + 8, height: 0))
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var addView: UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 74 * K320Scale, height: 74 * K320Scale))
        view.isUserInteractionEnabled = true
        view.image = UIImage.init(named: "ic_myalbum_add")
        view.contentMode = .center
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(addAction)))
        return view
    }()
}

extension TestAMuiltyImageViewController: DKImagePickerViewControllerDelegate {
    func didSelectModels(photos: [UIImage], infos: [Any], sourceAssets: [DKAssetModel]) {
        self.dataSource.append(contentsOf: sourceAssets)
        self.changeImgsView()
    }
}

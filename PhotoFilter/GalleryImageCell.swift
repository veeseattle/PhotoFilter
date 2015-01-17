//
//  GalleryCell.swift
//  PhotoFilter
//
//  Created by Vania Kurniawati on 1/12/15.
//  Copyright (c) 2015 Vania Kurniawati. All rights reserved.
//

import Foundation
import UIKit

class GalleryImageCell: UICollectionViewCell {
  
  let imageView = UIImageView()
  
  override init(frame: CGRect) {
    
    super.init(frame: frame)
    self.addSubview(self.imageView)
    self.backgroundColor = UIColor.whiteColor()
    imageView.frame = self.bounds
    imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
    imageView.layer.masksToBounds = true
    let views = ["imageView" : imageView]
    let mainImageConstraintX = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: nil, metrics: nil, views: views)
    let mainImageConstraintY = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: nil, metrics: nil, views: views)
    self.addConstraints(mainImageConstraintX)
    self.addConstraints(mainImageConstraintY)
    }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
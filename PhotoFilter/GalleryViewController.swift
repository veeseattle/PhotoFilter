//
//  GalleryViewController.swift
//  PhotoFilter
//
//  Created by Vania Kurniawati on 1/12/15.
//  Copyright (c) 2015 Vania Kurniawati. All rights reserved.
//

import UIKit

protocol ImageSelectedProtocol {
  func controllerDidSelectImage(UIImage) -> Void
}

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
  
  var rootView = UIView(frame: UIScreen.mainScreen().bounds)
  var galleryCollection : UICollectionView!
  var cellImages = [UIImage]()
  var imageView : UIImageView?
  var delegate : ImageSelectedProtocol?
  var collectionViewFlowLayout = UICollectionViewFlowLayout()
  
  override func loadView() {
    self.galleryCollection = UICollectionView(frame: rootView.frame, collectionViewLayout: collectionViewFlowLayout)
    self.galleryCollection.setTranslatesAutoresizingMaskIntoConstraints(false)
    rootView.addSubview(galleryCollection)
    
    self.view = rootView
    self.galleryCollection.dataSource = self
    self.galleryCollection.delegate = self
    collectionViewFlowLayout.itemSize = CGSize(width: 100, height: 100)
    
    let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: "galleryCollectionPinched:")
    self.galleryCollection.addGestureRecognizer(pinchRecognizer)
    
    
  }
  
    override func viewDidLoad() {
      
      super.viewDidLoad()
      self.galleryCollection.registerClass(GalleryImageCell.self, forCellWithReuseIdentifier: "Gallery_Cell")
      self.galleryCollection.backgroundColor = UIColor.whiteColor()
      let cellImage1 = UIImage(named: "street.jpeg")
      let cellImage2 = UIImage(named: "house.jpeg")
      let cellImage3 = UIImage(named: "beach.jpeg")
      let cellImage4 = UIImage(named: "moped.jpeg")
      let cellImage5 = UIImage(named: "dock.jpeg")
      let cellImage6 = UIImage(named: "cloud.jpeg")
      self.cellImages.append(cellImage1!)
      self.cellImages.append(cellImage2!)
      self.cellImages.append(cellImage3!)
      self.cellImages.append(cellImage4!)
      self.cellImages.append(cellImage5!)
        // Do any additional setup after loading the view.
    }

  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.cellImages.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = galleryCollection.dequeueReusableCellWithReuseIdentifier("Gallery_Cell", forIndexPath: indexPath) as GalleryImageCell
    let image = self.cellImages[indexPath.row]
    cell.imageView.image = image
    cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    self.delegate?.controllerDidSelectImage(self.cellImages[indexPath.row])
    self.navigationController?.popViewControllerAnimated(true) 
  }

  
  func galleryCollectionPinched(sender: UIPinchGestureRecognizer) {
    switch sender.state {
    case .Began:
      println("gesture recognizer started")
    case .Changed:
      self.galleryCollection.performBatchUpdates({ () -> Void in
        if sender.velocity > 0 {
          let newSize = CGSize(width: self.collectionViewFlowLayout.itemSize.width * 1.1, height: self.collectionViewFlowLayout.itemSize.height * 1.1)
          self.collectionViewFlowLayout.itemSize = newSize
        }
        else if sender.velocity < 0 {
          let newSize = CGSize(width: self.collectionViewFlowLayout.itemSize.width * 0.95, height: self.collectionViewFlowLayout.itemSize.height * 0.95)
          self.collectionViewFlowLayout.itemSize = newSize
        }
      }, completion: { (finished) -> Void in
        println("changed")
      })
      
    case .Ended:
      println("gesture recognizer terminated")
    default:
      println("default scenario fired")
    }}
}



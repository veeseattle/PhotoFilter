//
//  PhotoViewController.swift
//  PhotoFilter
//
//  Created by Vania Kurniawati on 1/14/15.
//  Copyright (c) 2015 Vania Kurniawati. All rights reserved.
//

import UIKit
import Photos

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

  var collectionView : UICollectionView!
  var rootView = UIView(frame: UIScreen.mainScreen().bounds)
  var delegate : ImageSelectedProtocol?
  var photoResult : PHFetchResult!
  var photoCollection : PHAssetCollection!
  var imageManager = PHCachingImageManager()
  
  override func loadView() {
    let rootView = UIView(frame: UIScreen.mainScreen().bounds)
    self.collectionView = UICollectionView(frame: rootView.bounds, collectionViewLayout: UICollectionViewFlowLayout())
    let flowLayout = collectionView.collectionViewLayout as UICollectionViewFlowLayout
    flowLayout.itemSize = CGSize(width: 100, height: 100)
    rootView.addSubview(collectionView)
    collectionView.setTranslatesAutoresizingMaskIntoConstraints(false)
    collectionView.backgroundColor = UIColor.whiteColor()
    self.view = rootView
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.imageManager = PHCachingImageManager()
    self.photoResult = PHAsset.fetchAssetsWithOptions(nil)
    self.collectionView.registerClass(GalleryImageCell.self, forCellWithReuseIdentifier: "Photo_Cell")
    self.view.backgroundColor = UIColor.whiteColor()
    self.collectionView.dataSource = self
    self.collectionView.delegate = self
    
        // Do any additional setup after loading the view.
    }
    
  //MARK: UICollectionViewDataSource
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.photoResult.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Photo_Cell", forIndexPath: indexPath) as GalleryImageCell
    let photoAsset = self.photoResult[indexPath.row] as PHAsset
    self.imageManager.requestImageForAsset(photoAsset, targetSize: CGSize(width: 100, height: 100), contentMode: PHImageContentMode.AspectFill, options: nil) { (requestedImage, info) -> Void in
      cell.imageView.image = requestedImage
      cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
    }
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let photoAsset = self.photoResult[indexPath.row] as PHAsset
    self.imageManager.requestImageForAsset(photoAsset, targetSize: CGSize(width: 100, height: 100), contentMode: PHImageContentMode.AspectFill, options: nil) { (requestedImage, info) -> Void in
    self.delegate?.controllerDidSelectImage(requestedImage)
    self.navigationController?.popToRootViewControllerAnimated(true)
  }
  }
  
  
  
}

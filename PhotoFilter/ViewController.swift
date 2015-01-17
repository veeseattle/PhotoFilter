//
//  ViewController.swift
//  PhotoFilter
//
//  Created by Vania Kurniawati on 1/12/15.
//  Copyright (c) 2015 Vania Kurniawati. All rights reserved.
//

import UIKit
import Social
import Accounts
import Foundation

class ViewController: UIViewController, ImageSelectedProtocol, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate {

  let photoButton = UIButton()
  var mainImage = UIImageView()
  let alertController = UIAlertController(title: NSLocalizedString("Options", comment: "Title for alert controller"), message: NSLocalizedString("Select photo source", comment: "Message within alert controller"), preferredStyle: UIAlertControllerStyle.ActionSheet)
  var collectionView : UICollectionView!
  var gpuContext : CIContext!
  var collectionViewYConstraint : NSLayoutConstraint!
  var mainImageShrinkConstraint : NSLayoutConstraint!
  var mainImageShrinkConstraintY : NSLayoutConstraint!
  var originalThumbnail : UIImage!
  var filterNames = [String]()
  let imageQueue = NSOperationQueue()
  var thumbnails = [Thumbnail]()
  var doneButton : UIBarButtonItem!
  var shareButton : UIBarButtonItem!
  var delegate : ImageSelectedProtocol?
  var views : [String : AnyObject]?
  var selectedMainPhoto = UIImageView()
  var dogDictionary = [Int : UIImage]()
  
  override func loadView() {
    
    //mainImage
    let rootView = UIView(frame: UIScreen.mainScreen().bounds)
    rootView.backgroundColor = UIColor.whiteColor()
    let mainImageFile = UIImage(named: "street.jpeg")
    self.mainImage = UIImageView(image: mainImageFile!)
    self.mainImage.contentMode = UIViewContentMode.ScaleToFill
    self.mainImage.setTranslatesAutoresizingMaskIntoConstraints(false)
    
    //button
    self.photoButton.setTitle(NSLocalizedString("Photo", comment: "Button title"), forState: UIControlState.Normal)
    self.photoButton.backgroundColor = UIColor.blueColor()
    self.photoButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.photoButton.addTarget(self, action: "photoButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
    
    //collectionView
    let collectionViewFlowLayout = UICollectionViewFlowLayout()
    self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewFlowLayout)
    collectionView.setTranslatesAutoresizingMaskIntoConstraints(false)
    collectionViewFlowLayout.itemSize = CGSize(width: 100, height: 100)
    collectionView.backgroundColor = UIColor.whiteColor()
    collectionViewFlowLayout.scrollDirection = .Horizontal
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.registerClass(GalleryImageCell.self, forCellWithReuseIdentifier: "Filter_Cell")
    
    //view setup
    let views = [ "photoButton" : photoButton, "mainImage" : mainImage, "collectionView" : collectionView]
    rootView.addSubview(mainImage)
    rootView.addSubview(collectionView)
    rootView.addSubview(photoButton)
    self.setupConstraintsOnRootView(rootView, forView: views)
    self.view = rootView
    self.navigationController?.delegate = self
    
    //doubleTap set up
    self.mainImage.userInteractionEnabled = true
    let tapTapJoy = UITapGestureRecognizer(target: self, action: "doubleTapToFilter:")
    tapTapJoy.numberOfTapsRequired = 2
    self.mainImage.addGestureRecognizer(tapTapJoy)
    
    
  }
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
  
    //set up camera option
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) == true {
      let cameraAction = UIAlertAction(title: NSLocalizedString("Camera", comment: "Camera option within Photo's action sheet"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
        let cameraOption = UIImagePickerController()
        cameraOption.sourceType = UIImagePickerControllerSourceType.Camera
        cameraOption.allowsEditing = true
        cameraOption.delegate = self
        self.presentViewController(cameraOption, animated: true, completion: nil)
      })
      self.alertController.addAction(cameraAction)
    }
    
    //set up photo view collection
    let photoCollectionAction = UIAlertAction(title: NSLocalizedString("Photo", comment: "Photo view option within Photo's action sheet"), style: UIAlertActionStyle.Default) { (action) -> Void in
      let photoVC = PhotoViewController()
      photoVC.delegate = self
      self.navigationController?.pushViewController(photoVC, animated: true)
    }
    self.alertController.addAction(photoCollectionAction)
    
    //set up gallery button
    let galleryAction = UIAlertAction(title: NSLocalizedString("Gallery", comment: "Gallery option within Photo's action sheet"), style: UIAlertActionStyle.Default) { (action) -> Void in
      println("gallery pushed")
      let galleryVC = GalleryViewController()
      galleryVC.delegate = self
      self.navigationController?.pushViewController(galleryVC, animated: true)
    }
    self.alertController.addAction(galleryAction)
    
    //set up filter button
    let filterAction = UIAlertAction(title: NSLocalizedString("Filter", comment: "Filter option within Photo's action sheet"), style: UIAlertActionStyle.Default) { (action) -> Void in
      self.controllerDidSelectImage(self.mainImage.image!)
      self.collectionViewYConstraint.constant = 50
      UIView.animateWithDuration(0.4, animations: { () -> Void in
        self.navigationItem.rightBarButtonItem = self.doneButton
      })
      self.mainImageShrinkConstraintY.constant = 150
      self.mainImageShrinkConstraint.constant = 150
      UIView.animateWithDuration(0.4, animations: { () -> Void in
        self.view.layoutIfNeeded()
      })
    }
    self.alertController.addAction(filterAction)
    
    //set up random dog image fetch
    let dummyAction = UIAlertAction(title: NSLocalizedString("Click me!", comment: "Fetches a random Keeshond picture from Google Custom Search API"), style: UIAlertActionStyle.Default) { (action) -> Void in
      self.fetchImage(1, completionHandler: { (selectedImage, errorString) -> () in
      
      })
    }
    self.alertController.addAction(dummyAction)
   
    let options = [kCIContextWorkingColorSpace : NSNull()]
    let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    self.gpuContext = CIContext(EAGLContext: eaglContext, options: options)
    self.setupThumbnails()
    
    
    self.doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
    self.shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "sharePressed")
    self.navigationItem.rightBarButtonItem = self.shareButton
  
    
    // Do any additional setup after loading the view, typically from a nib.
  
  }
  

  func setupThumbnails() {
    self.filterNames = ["CISepiaTone","CIPhotoEffectChrome", "CIPhotoEffectNoir", "CIVignette"]
    for filter in self.filterNames {
      let thumbnail = Thumbnail(filterName: filter, operationQueue: self.imageQueue, context: self.gpuContext)
      self.thumbnails.append(thumbnail)
    }}
  
  
  //MARK: ImageSelectedDelegate
  func controllerDidSelectImage(image: UIImage) {
    self.mainImage.image = image
    self.selectedMainPhoto.image = image
    self.generateThumbnail(image)
    for thumbnail in self.thumbnails {
      thumbnail.originalImage = self.originalThumbnail
      thumbnail.filteredImage = nil
    }
    self.collectionView.reloadData()
  }
  
  
  //MARK: OptionSelector
  func photoButtonPressed(sender : UIButton) {
    self.presentViewController(self.alertController, animated: true, completion: nil)
  }
  
  
  //MARK: CreateThumbnail
  func generateThumbnail(originalImage: UIImage) {
    let size = CGSize(width: 100, height: 100)
    UIGraphicsBeginImageContext(size)
    originalImage.drawInRect(CGRect(x: 0, y: 0, width: 100, height: 100))
    self.originalThumbnail = UIGraphicsGetImageFromCurrentImageContext()
  }
  
  func donePressed () {
    self.collectionViewYConstraint.constant = -120
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
    self.navigationItem.rightBarButtonItem = shareButton
    
  }
    
  func sharePressed () {
    if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
      var socialAccountController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
      socialAccountController.addImage(self.mainImage.image)
      self.presentViewController(socialAccountController, animated: true, completion: nil)}
    else {
      //prompt user to log in to Twitter account
      var accountStore = ACAccountStore()
      let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
      accountStore.requestAccessToAccountsWithType(accountType, options: nil) {(granted: Bool, error: NSError!) -> Void in
        if granted {
          let twitterAccounts = accountStore.accountsWithAccountType(accountType)
          //check to make sure account is not empty
          if !twitterAccounts.isEmpty {
            //take first twitter account
            var twitterAccount = twitterAccounts.first as? ACAccount
          }
        }
      }}
  }
  
  
  //MARK: UIImagePickerControllerDelegate
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    self.dismissViewControllerAnimated(true, completion: nil)

  }
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    let selectedImage = info[UIImagePickerControllerEditedImage] as UIImage
    self.mainImage.image = selectedImage
    self.dismissViewControllerAnimated(true, completion: nil)
    self.controllerDidSelectImage(selectedImage)
    self.selectedMainPhoto.image = selectedImage
  }
    
  
  
  //MARK: UICollectionViewDataSource
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.thumbnails.count
    }

  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Filter_Cell", forIndexPath: indexPath) as GalleryImageCell
    let thumbnail = thumbnails[indexPath.row]
    if thumbnail.originalImage != nil {
      if thumbnail.filteredImage == nil {
        thumbnail.generateFilteredImage()
        cell.imageView.image = thumbnail.filteredImage!
        cell.backgroundColor = UIColor.whiteColor()
        cell.imageView.layer.cornerRadius = 50.0
        cell.imageView.layer.masksToBounds = true
        cell.opaque = false
      }}
    return cell
    }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let selectedPhoto = thumbnails[indexPath.row]
    let filterName = selectedPhoto.filterName
    let startImage = CIImage(image: self.selectedMainPhoto.image)
    let filter = CIFilter(name: filterName)
    filter.setValue(startImage, forKey: kCIInputImageKey)
    let result = filter.valueForKey(kCIOutputImageKey) as CIImage
    let imageRef = self.gpuContext.createCGImage(result, fromRect: result.extent())
    self.mainImage.image = UIImage(CGImage: imageRef)
  
    }

  
  func fetchImage(currentID : Int, completionHandler : (UIImage?, String?) -> ()) {
    var randomNumber = Int(arc4random_uniform(10))
    var selectedImage : UIImage
    //image caching
    if let a = dogDictionary[randomNumber] {
      selectedImage = a
      self.mainImage.image = selectedImage
    }
    else {
    var url = NSURL(string: "https://www.googleapis.com/customsearch/v1?key=AIzaSyAsX5ObwMmRmaxyQDaDNLD0Y8GVwA5wxy0&cx=017633276240633998306:xb_qdycw1ds&q=keeshond&searchType=image")
    var request = NSURLRequest(URL: url!)
    let queue = NSOperationQueue()
    NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (request, response, error) -> Void in
      var returnedData: [NSString: AnyObject] = NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.allZeros, error: nil) as [NSString : AnyObject]
      var dogInfo: [AnyObject] = returnedData["items"]! as [AnyObject]
      var randomDog = dogInfo[randomNumber] as [NSString : AnyObject]
      var randomLink = NSURL(string: randomDog["link"] as String)
      var randomImageData = NSData(contentsOfURL: randomLink!)
      var randomImage = UIImage(data: randomImageData!)
      self.dogDictionary[randomNumber] = randomImage
      NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
        completionHandler(randomImage, nil)
        self.mainImage.image = randomImage!
      })
      }}
    self.mainImageShrinkConstraintY.constant = 175
    self.mainImageShrinkConstraint.constant = 175
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      self.view.layoutIfNeeded()})
  }
  
  
  func doubleTapToFilter(sender: UITapGestureRecognizer) {
    
    self.controllerDidSelectImage(self.mainImage.image!)
    
    self.collectionViewYConstraint.constant = 50
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      self.navigationItem.rightBarButtonItem = self.doneButton
    })
    self.mainImageShrinkConstraintY.constant = 150
    self.mainImageShrinkConstraint.constant = 150
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
  }
  
  //MARK: Layout Constraints
  func setupConstraintsOnRootView(rootView: UIView, forView views: [String : AnyObject]) {
    let mainImageConstraintX = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[mainImage]-20-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
    let mainImageConstraintY = NSLayoutConstraint.constraintsWithVisualFormat("V:|-40-[mainImage]-40-|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(mainImageConstraintX)
    rootView.addConstraints(mainImageConstraintY)
    self.mainImageShrinkConstraintY = mainImageConstraintY.first as NSLayoutConstraint
    self.mainImageShrinkConstraint = mainImageConstraintY[1] as NSLayoutConstraint
    
    
    let photoButtonConstraintY = NSLayoutConstraint.constraintsWithVisualFormat("V:[photoButton]-200-|", options: nil, metrics: nil, views: views)
    let photoButton = views["photoButton"] as UIView!
    let photoButtonConstraintX = NSLayoutConstraint(item: photoButton, attribute: .CenterX, relatedBy: .Equal, toItem: rootView, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
    rootView.addConstraint(photoButtonConstraintX)
    rootView.addConstraints(photoButtonConstraintY)
    photoButton.setContentHuggingPriority(750, forAxis: UILayoutConstraintAxis.Vertical)
    
    let collectionViewConstraintX = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: nil, metrics: nil, views: views)
    let collectionViewConstraintY = NSLayoutConstraint.constraintsWithVisualFormat("V:[collectionView]-(-120)-|", options: nil, metrics: nil, views: views)
    let collectionViewSize = NSLayoutConstraint.constraintsWithVisualFormat("V:[collectionView(110)]", options: nil, metrics: nil, views: views)
    rootView.addConstraints(collectionViewConstraintX)
    rootView.addConstraints(collectionViewConstraintY)
    self.collectionView.addConstraints(collectionViewSize)
    self.collectionViewYConstraint = collectionViewConstraintY.first as NSLayoutConstraint
    
    }
  

  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

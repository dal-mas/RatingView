//
//  RatingView.swift
//
//  Copyright © 2016 Felipe Eulalio. All rights reserved.
//

import UIKit

@IBDesignable class RatingView: UIView
{
	// MARK: - Private Parameters
	
	/// Array to keep all the empty image views.
	fileprivate var emptyImageViews: [UIImageView] = []
	
	/// Array to keep all the full image views.
	fileprivate var fullImageViews: [UIImageView] = []
	
	// MARK: - Inspectable Parameters
	
	/// Image of the full rating.
	@IBInspectable var fullImage: UIImage? {
		didSet {
			for imageView in fullImageViews {
				imageView.image = fullImage
			}
		}
	}
	
	/// Image of the empty rating.
	@IBInspectable var emptyImage: UIImage? {
		didSet {
			for imageView in emptyImageViews {
				imageView.image = emptyImage
			}
		}
	}
	
	/// The maximum rating.
	@IBInspectable var maxValue: Int = 5 {
		didSet {
			assert(maxValue >= minValue, "The minimum value can't be bigger than the maximum value")
			
			if currentValue > Float(maxValue) {
				currentValue = Float(maxValue)
			}
			
			setViews()
		}
	}
	
	/// The minimum rating.
	@IBInspectable var minValue: Int = 0 {
		didSet {
			assert(minValue <= maxValue, "The minimum value can't be bigger than the maximum value")
			
			if currentValue < Float(minValue) {
				currentValue = Float(minValue)
				update()
			}
		}
	}
	
	/// The current value.
	@IBInspectable var currentValue: Float = 0 {
		didSet {
			if oldValue == currentValue { return }
			
			currentValue = currentValue > Float(maxValue) ? Float(maxValue) : currentValue
			currentValue = currentValue < Float(minValue) ? Float(minValue) : currentValue
			
			update()
		}
	}
	
	/// The pace which the value will change. The value might be between 0 and 1.
	/// If zero, the value will be the exact one.
	@IBInspectable var pace: Float = 1 {
		didSet {
			assert(pace >= 0 && pace <= 1, "Pace might be a value between 0 and 1")
		}
	}
	
	/// Defines if the view is touchable or not
	@IBInspectable var touchable: Bool = true {
		didSet {
			self.isUserInteractionEnabled = touchable
		}
	}
	
	// MARK: - View lifecycle
	
	required override init(frame: CGRect)
	{
		super.init(frame: frame)
		setViews()
		isUserInteractionEnabled = touchable
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		setViews()
		isUserInteractionEnabled = touchable
	}
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		layoutImageViews()
	}
	
	// MARK: - Subviews initilializer
	
	/**
	Set all the image views from the view. If they already exists, delete all and reset the arrays.
	*/
	fileprivate func setViews()
	{
		// Remove and reset the older image views
		for imageView in (emptyImageViews + fullImageViews) {
			imageView.removeFromSuperview()
		}
		
		emptyImageViews.removeAll(keepingCapacity: false)
		fullImageViews.removeAll(keepingCapacity: false)
		
		// Set the new image views
		for _ in 0..<maxValue {
			emptyImageViews.append(UIImageView(image: emptyImage))
			fullImageViews.append(UIImageView(image: fullImage))
		}
		
		for imageView in (emptyImageViews + fullImageViews) {
			imageView.contentMode = .scaleAspectFit
			self.addSubview(imageView)
		}
	}
	
	// MARK: - Presentation Methods
	
	/**
	Layout the image views for the best size.
	*/
	fileprivate func layoutImageViews()
	{
		var count = 0
		
		// Get the side where all the images can be displayed
		let imageSide = self.frame.width < (CGFloat(maxValue) * self.frame.height) ? self.frame.width / CGFloat(maxValue) : self.frame.height
		let imageSize = CGSize(width: imageSide, height: imageSide)
		
		for (empty, full) in zip(emptyImageViews, fullImageViews) {
			let origin = CGPoint(x: CGFloat(count) * imageSide, y: self.frame.height / 2 - imageSide / 2)
			
			empty.frame = CGRect(origin: origin, size: imageSize)
			full.frame = CGRect(origin: origin, size: imageSize)
			
			count += 1
		}
		
		update()
	}
	
	/**
	Update the image views according to the current value.
	*/
	fileprivate func update()
	{
		var count  = 0
		let fullCount = Int(currentValue) // The integer part
		let remainder = CGFloat(currentValue - Float(fullCount)) // The decimal part
		
		for imageView in fullImageViews {
			if count < fullCount {
				// Show the full image view
				imageView.layer.mask = nil
				imageView.isHidden = false
			} else if count == fullCount {
				// Set a mask to display only a part of the image view
				let mask = CALayer()
				mask.frame = CGRect(x: 0, y: 0, width: remainder * imageView.frame.width, height: imageView.frame.height)
				
				mask.backgroundColor = UIColor.black.cgColor
				
				imageView.layer.mask = mask
				imageView.isHidden = false
			} else {
				// Doesn't not show the image view
				imageView.layer.mask = nil
				imageView.isHidden = true
			}
			
			count += 1
		}
	}
	
	// MARK: - Touch Events
	
	/**
	Get the rating from a given point where the touch event occurred.
	- parameter location: Point from the touch event.
	*/
	fileprivate func setRatingFromTouch(in location: CGPoint)
	{
		guard location.x < self.frame.width else { return }
		
		var floatingPart: Float = 0.0
		
		for imageView in emptyImageViews.reversed() {
			if location.x > imageView.frame.origin.x {
				// Convert to the location in the image view
				let locationInIV = imageView.convert(location, from: self)
				
				floatingPart = Float(locationInIV.x / imageView.frame.width)
				
				if pace != 0 {
					floatingPart = Float(Int(floatingPart / pace) + 1) * pace
				}
				
				currentValue = Float(emptyImageViews.index(of: imageView)!) + floatingPart
				
				return
			}
		}
		
		// If the touch isn't in any of the views, the value might be zero
		currentValue = 0.0
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
	{
		if let touch = touches.first {
			let location = touch.location(in: self)
			setRatingFromTouch(in: location)
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
	{
		if let touch = touches.first {
			let location = touch.location(in: self)
			setRatingFromTouch(in: location)
		}
	}
}

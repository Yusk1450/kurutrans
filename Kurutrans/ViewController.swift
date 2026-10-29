//
//  ViewController.swift
//  Kurutrans
//
//  Created by ISHIGO Yusuke on 2026/10/28.
//

import UIKit

class ViewController: UIViewController, RotationDetectorDelegate
{
	@IBOutlet weak var imageView: UIImageView!
	
	let detector = RotationDetector()
	
	let imageBaseName = "hamster"
	let imageCount = 5
	var frameIndex = 0

	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.detector.delegate = self
		self.detector.start()
		
		self.imageView.image = UIImage(named: "\(self.imageBaseName)_\(self.frameIndex)")
	}
	
	func rotationDetectorOnUpdate(rotationDetector: RotationDetector, radians: Double)
	{
		self.imageView.transform = CGAffineTransform(rotationAngle: radians)
	}
	
	func rotationDetectorOnThreashold(rotationDetector: RotationDetector)
	{
		self.frameIndex = (self.frameIndex + 1) % self.imageCount
		self.imageView.image = UIImage(named: "\(self.imageBaseName)_\(self.frameIndex)")
	}
	
	func rotationDetectorDidStatusChanged(rotationDetector: RotationDetector, isFlat: Bool)
	{
		
	}

}


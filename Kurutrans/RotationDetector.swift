//
//  RotationDetector.swift
//  Kurutrans
//
//  Created by ISHIGO Yusuke on 2026/10/28.
//

import UIKit
import CoreMotion

protocol RotationDetectorDelegate: AnyObject
{
	func rotationDetectorOnThreashold(rotationDetector:RotationDetector)
	func rotationDetectorOnUpdate(rotationDetector:RotationDetector, radians:Double)
}

class RotationDetector: NSObject
{
	let motionManager = CMMotionManager()
	let queue = OperationQueue()
	
	var threasholdDegrees:Double = 10.0
	
	var lastTimestamp:TimeInterval?
	// 累積回転
	var totalRotation:Double = 0.0
	var lastTotalRotation:Double = 0.0

	var delegate:RotationDetectorDelegate?
	
	var isRunning = false
	
	
	override init()
	{
		self.queue.name = "RotationDetector"
		self.queue.maxConcurrentOperationCount = 1
	}
	
	/*
	 * 計測開始
	 */
	func start()
	{
		guard self.motionManager.isDeviceMotionAvailable else
		{
			print("ERROR: MotionAvailable")
			return
		}
		
		self.stop()
		
		self.isRunning = true
		
		self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
		self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical,
													to: self.queue) { [weak self] motion, _ in
			guard let self, let motion else { return }
			
			let gravityZ = motion.gravity.z
			var isFlat = false
			if (abs(gravityZ) >= 0.85)
			{
				isFlat = true
			}
			
			// 水平じゃなかったら
			guard isFlat else
			{
				Task { @MainActor in
					self.delegate?.rotationDetectorOnUpdate(rotationDetector: self, radians: self.totalRotation)
				}
				return
			}
			
			let timestamp = motion.timestamp
			guard let lastTimestamp else {
				self.lastTimestamp = timestamp
				Task { @MainActor in
					self.delegate?.rotationDetectorOnUpdate(rotationDetector: self, radians: self.totalRotation)
				}
				return
			}
			
			let dt = timestamp - lastTimestamp
			guard dt > 0, dt < 0.5 else
			{
				self.lastTimestamp = timestamp
				Task { @MainActor in
					self.delegate?.rotationDetectorOnUpdate(rotationDetector: self, radians: self.totalRotation)
				}
				return
			}
			
			let rotation = gravityZ >= 0 ? -motion.rotationRate.z : motion.rotationRate.z
			self.totalRotation += rotation * dt
			self.lastTimestamp = timestamp
			
			Task { @MainActor in
				self.delegate?.rotationDetectorOnUpdate(rotationDetector: self, radians: self.totalRotation)
			}
			
			let delta = self.totalRotation - self.lastTotalRotation
			// 差分がしきい値を超えたとき
			if (abs(delta) >= threasholdDegrees * .pi / 180)
			{
				self.lastTotalRotation = self.totalRotation

				Task { @MainActor in
					self.delegate?.rotationDetectorOnThreashold(rotationDetector: self)
				}
			}
		}
		
	}

	/*
	 * 計測終了
	 */
	func stop()
	{
		self.motionManager.stopDeviceMotionUpdates()
		self.isRunning = false
	}
	
	
}

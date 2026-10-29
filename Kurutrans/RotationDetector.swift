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
	// しきい値を超えた場合
	func rotationDetectorOnThreashold(rotationDetector:RotationDetector)
	// 毎フレーム呼ばれる
	func rotationDetectorOnUpdate(rotationDetector:RotationDetector, radians:Double)
	// 水平状態が変化したら呼び出される
	func rotationDetectorDidStatusChanged(rotationDetector:RotationDetector, isFlat:Bool)
}

class RotationDetector: NSObject
{
	let motionManager = CMMotionManager()
	let queue = OperationQueue()
	
	var threasholdDegrees:Double = 10.0
	
	// 前回の計測時間
	var lastTimestamp:TimeInterval?
	// 累積回転量
	var totalRotation:Double = 0.0
	var lastTotalRotation:Double = 0.0

	var isFlat = false
	var isLastFlat = false
	
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
			self.isFlat = false
			if (abs(gravityZ) >= 0.85)
			{
				self.isFlat = true
			}
			
			// 状態が変化した
			if (self.isFlat != self.isLastFlat)
			{
				self.delegate?.rotationDetectorDidStatusChanged(rotationDetector: self, isFlat: self.isFlat)
			}
			self.isLastFlat = self.isFlat
			
			// 水平じゃなかったら
			guard self.isFlat else
			{
				return
			}
			
			let timestamp = motion.timestamp
			guard let lastTimestamp else {
				self.lastTimestamp = timestamp
				return
			}
			
			let dt = timestamp - lastTimestamp
			guard dt > 0, dt < 0.5 else
			{
				self.lastTimestamp = timestamp
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
		self.totalRotation = 0.0
		self.lastTotalRotation = 0.0
		self.lastTimestamp = nil
		
		self.isRunning = false
	}
	
	
}

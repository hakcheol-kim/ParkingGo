//
//  Extension.swift
//  PakingGo
//
//  Created by 김학철 on 2021/02/28.
//

import Foundation
import UIKit

let TAG_LOADING_IMG = 20210101

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

extension UIView {
    func startAnimation(raduis: CGFloat) {
        let imageName = "ico_loader"

        let indicator = viewWithTag(TAG_LOADING_IMG) as? UIImageView
        if indicator != nil {
            indicator?.removeFromSuperview()
        }

        isHidden = false
        superview?.bringSubviewToFront(self)

        let ivIndicator = UIImageView(frame: CGRect(x: 0, y: 0, width: 2 * raduis, height: 2 * raduis))
        ivIndicator.tag = TAG_LOADING_IMG
        ivIndicator.contentMode = .scaleAspectFit
        ivIndicator.image = UIImage(named: imageName)
        addSubview(ivIndicator)
//        indicator?.layer.borderWidth = 1.0
//        indicator?.layer.borderColor = UIColor.red.cgColor
        ivIndicator.frame = CGRect(x: (frame.size.width - ivIndicator.frame.size.width) / 2, y: (frame.size.height - ivIndicator.frame.size.height) / 2, width: ivIndicator.frame.size.width, height: ivIndicator.frame.size.height)

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = NSNumber(value: 0.0)
        rotation.toValue = NSNumber(value: -2.0 * Double(CGFloat.pi))
        rotation.duration = 1
        rotation.repeatCount = .infinity

        ivIndicator.layer.add(rotation, forKey: "loading")
    }
    func stopAnimation() {
        isHidden = true
        let indicator = viewWithTag(TAG_LOADING_IMG) as? UIImageView
        if indicator != nil {
            indicator?.layer.removeAnimation(forKey: "loading")
            //        [indicator removeFromSuperview];
        }
    }
    
}

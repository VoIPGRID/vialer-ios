//
//  GradientView.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import UIKit

@IBDesignable class GradientView: UIView {
    private var gradientLayer: CAGradientLayer!

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    override func layoutSubviews() {
        let startColor = ColorsConfiguration.shared.gradientColors(.start)
        let endColor = ColorsConfiguration.shared.gradientColors(.end)
        self.gradientLayer = self.layer as! CAGradientLayer
        self.gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        self.gradientLayer.startPoint = createStartPoint()
        self.gradientLayer.endPoint = createEndPoint()
    }

    fileprivate func createStartPoint() -> CGPoint {
        let xPi = calcSin(offset: 0.75)
        let x = powf(xPi, 2);

        let yPi = calcSin(offset: 0)
        let y = powf(yPi, 2);

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    fileprivate func createEndPoint() -> CGPoint {
        let xPi = calcSin(offset: 0.25)
        let x = powf(xPi, 2);

        let yPi = calcSin(offset: 0.5)
        let y = powf(yPi, 2)

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    fileprivate func calcSin(offset: Float) -> Float {
        let angle: Float = ColorsConfiguration.shared.backgroundGradientAngle / 360
        let anglePlusOffset: Float = (angle + offset) / 2
        let piCalc: Float = 2.0 * .pi * anglePlusOffset
        return sinf(piCalc)
    }

}

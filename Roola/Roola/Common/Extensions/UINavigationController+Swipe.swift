//
//  UINavigationController+Swipe.swift
//  Roola
//
//  Created by Lin Dan Christiano on 20/11/25.
//

import SwiftUI

// Tambahkan extension ini di luar struct View manapun
extension UINavigationController: @preconcurrency UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Izinkan gesture swipe back hanya jika ada lebih dari 1 view di stack
        return viewControllers.count > 1
    }
}

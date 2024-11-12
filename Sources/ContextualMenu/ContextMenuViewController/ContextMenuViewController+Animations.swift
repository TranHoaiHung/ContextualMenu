//
//  ContextMenuViewController+Animations.swift
//  
//
//  Created by Thibaud David on 21/02/2023.
//

import Foundation
import UIKit

// Animations completion closure is called once preview animation is done.
// Depending on your animation parameters for Menu / AccessoryView,
// completion might be called before all animations are done.
// In the future, we might consider synchronizing all animations if needed
// using keyframes animations
// ETA: "Flemme 🥖"©
extension ContextMenuViewController: ContextMenuAnimatable {
    public func appearAnimation(completion: (() -> Void)? = nil) {
        // Kích hoạt các ràng buộc cần thiết trước khi layout
        NSLayoutConstraint.activate(constraintsAlteringPreviewPosition)
        view.layoutIfNeeded() // Sử dụng layoutIfNeeded() để áp dụng ngay các thay đổi

        previewRendering.layer.applyShadow(style.preview.shadow, overrideOpacity: 0)
        previewRendering.layer.animate(
            keyPath: \.shadowOpacity,
            toValue: style.preview.shadow.opacity,
            duration: style.apparition.duration
        )
        menuView?.appearAnimation()
        animatableAccessoryView?.appearAnimation() ?? (accessoryView?.alpha = 0)

        // Thực hiện animation mở menu với UIView.animate
        UIView.animate(
            withDuration: style.apparition.duration,
            delay: 0,
            usingSpringWithDamping: style.apparition.damping,
            initialSpringVelocity: style.apparition.initialSpringVelocity,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut], // Thêm curveEaseOut để mượt hơn
            animations: { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
                self.backgroundBlur.alpha = self.style.blurAlpha
                self.previewRendering.transform = self.style.preview.transform

                if self.animatableAccessoryView == nil {
                    // Thực hiện animation mặc định khi cần
                    self.accessoryView?.alpha = 1
                }
            },
            completion: { _ in completion?() }
        )
    }

    public func disappearAnimation(completion: (() -> Void)? = nil) {
        // Hủy bỏ các ràng buộc trước khi layout
        NSLayoutConstraint.deactivate(constraintsAlteringPreviewPosition)
        view.layoutIfNeeded() // Sử dụng layoutIfNeeded() để áp dụng thay đổi nhanh chóng

        previewRendering.layer.animate(
            keyPath: \.shadowOpacity,
            toValue: 0,
            duration: style.disapparition.duration
        )
        menuView?.disappearAnimation()
        animatableAccessoryView?.disappearAnimation()

        // Thực hiện animation biến mất
        UIView.animate(
            withDuration: style.disapparition.duration,
            delay: 0,
            usingSpringWithDamping: style.disapparition.damping,
            initialSpringVelocity: style.disapparition.initialSpringVelocity,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseIn], // Thêm curveEaseIn để tạo cảm giác mượt hơn
            animations: { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
                self.backgroundBlur.alpha = 0
                self.previewRendering.transform = .identity

                if self.animatableAccessoryView == nil {
                    // Thực hiện animation mặc định nếu cần
                    self.accessoryView?.alpha = 0
                }
            },
            completion: { [weak self] _ in
                self?.targetedPreview?.view.alpha = 1

                // Đặt targetedPreview về nil để phá vỡ vòng lặp giữ nếu có
                self?.targetedPreview = nil
                completion?()
            }
        )
    }
}

//
//  MenuView.swift
//  
//
//  Created by Thibaud David on 08/02/2023.
//

import Foundation
import UIKit

protocol MenuViewDelegate: AnyObject {
    func dismissMenuView(menuView: MenuView, uponTapping menuElement: MenuElement)
}

public final class MenuView: UIView {
    let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let menu: Menu
    let style: Style

    let anchorPointAlignment: Alignment

    weak var delegate: MenuViewDelegate?

    init(menu: Menu, anchorPointAlignment: Alignment, style: Style, delegate: MenuViewDelegate?) {
        self.menu = menu
        self.style = style
        self.anchorPointAlignment = anchorPointAlignment
        self.delegate = delegate

        super.init(frame: .zero)

        clipsToBounds = true
        layer.cornerRadius = style.cornerRadius
        backgroundColor = style.backgroundColor
        alpha = 0.0 // Set initial alpha to 0 for smooth animation

        for child in menu.children {
            let elementView = MenuElementView(element: child, style: style.element, delegate: self)
            stackView.addArrangedSubview(elementView)
        }

        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.widthAnchor.constraint(equalToConstant: style.width),
            stackView.heightAnchor.constraint(equalToConstant: CGFloat(menu.children.count) * style.element.height)
        ])

        // Animate the appearance of the menu view to reduce flicker
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1.0
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension MenuView: MenuElementViewDelegate {
    func menuElementViewTapped(menuElementView: MenuElementView) {
        delegate?.dismissMenuView(menuView: self, uponTapping: menuElementView.element)
    }
}

//
//  ContextMenuViewController.swift
//
//
//  Created by Thibaud David on 06/02/2023.
//

import UIKit

protocol ContextMenuViewControllerDelegate: AnyObject {
    func dismissContextMenuViewController(
        _ contextMenuViewController: ContextMenuViewController,
        interaction: ContextMenuInteractor.Interaction,
        uponTapping menuElement: MenuElement?
    )
}

class ContextMenuViewController: UIViewController {

    internal lazy var backgroundBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: style.backgroundBlurStyle))
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.alpha = 0

        let gesture = UITapGestureRecognizer(
            target: self, action: #selector(onTouchUpInsideBackground)
        )
        v.addGestureRecognizer(gesture)
        return v
    }()

    private lazy var previewTransformedBoundingView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    let style: ContextMenuStyle
    let interaction: ContextMenuInteractor.Interaction
    let menuConfiguration: ContextMenuConfiguration?
    var targetedPreview: UITargetedPreview?
    let previewRendering: UIView
    let baseFrameInScreen: CGRect
    let accessoryView: UIView?
    var menuView: MenuView?
    var animatableAccessoryView: ContextMenuAnimatable? { accessoryView as? ContextMenuAnimatable }
    weak var delegate: ContextMenuViewControllerDelegate?

    var constraintsAlteringPreviewPosition = [NSLayoutConstraint]()

    init(
        interaction: ContextMenuInteractor.Interaction,
        view: UIView,
        targetedPreview: UITargetedPreview,
        baseFrameInScreen: CGRect,
        delegate: ContextMenuViewControllerDelegate?
    ) {
        let configuration = interaction.menuConfigurationProvider(view)

        self.interaction = interaction
        self.menuConfiguration = configuration
        self.targetedPreview = targetedPreview
        self.previewRendering = targetedPreview.view.snapshotView(afterScreenUpdates: false) ?? UIView()
        self.baseFrameInScreen = baseFrameInScreen
        self.accessoryView = configuration?.accessoryView
        self.style = interaction.style
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = style.backgroundColor

        let alignmentToPreview = menuAndAccessoryViewAlignment()

        let backgroundConstraints = setupBackgroundBlur()
        let previewConstraints = setupPreview()
        let accessoryViewConstraints = setupAccessoryViewIfNeeded(alignment: alignmentToPreview)
        let menuConstraints = setupMenuViewIfNeeded(alignment: alignmentToPreview)

        NSLayoutConstraint.activate(
            backgroundConstraints.fixed
            + accessoryViewConstraints.fixed
            + previewConstraints.fixed
            + menuConstraints.fixed
        )

        constraintsAlteringPreviewPosition.append(contentsOf:
            backgroundConstraints.animatable
            + accessoryViewConstraints.animatable
            + previewConstraints.animatable
            + menuConstraints.animatable
        )

        view.layoutIfNeeded()
    }

    private func setupBackgroundBlur() -> FixedAndAnimatableConstraints {
        view.addSubview(backgroundBlur)
        return .init(
            fixed: [
                backgroundBlur.topAnchor.constraint(equalTo: view.topAnchor),
                backgroundBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                backgroundBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                backgroundBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ],
            animatable: []
        )
    }
    private func setupPreview() -> FixedAndAnimatableConstraints {
        previewRendering.translatesAutoresizingMaskIntoConstraints = false

        previewTransformedBoundingView.addSubview(previewRendering)
        view.addSubview(previewTransformedBoundingView)
        // Animate fading out instead of immediately setting alpha
        UIView.animate(withDuration: 0.2) {
            self.targetedPreview?.view.alpha = 0
        }

        return FixedAndAnimatableConstraints(
            fixed: [
                previewRendering.leadingAnchor.constraint(
                    equalTo: view.leadingAnchor, constant: baseFrameInScreen.minX
                ).priority(.defaultHigh),
                previewRendering.topAnchor.constraint(
                    equalTo: view.topAnchor,
                    constant: baseFrameInScreen.minY
                ).priority(.defaultHigh),
                previewRendering.widthAnchor.constraint(equalToConstant: baseFrameInScreen.width),
                previewRendering.heightAnchor.constraint(equalToConstant: baseFrameInScreen.height),
                previewTransformedBoundingView.widthAnchor.constraint(
                    equalToConstant: baseFrameInScreen.width * style.preview.transform.a
                ),
                previewTransformedBoundingView.heightAnchor.constraint(
                    equalToConstant: baseFrameInScreen.height * style.preview.transform.d
                ),
                previewTransformedBoundingView.centerXAnchor.constraint(equalTo: previewRendering.centerXAnchor),
                previewTransformedBoundingView.centerYAnchor.constraint(equalTo: previewRendering.centerYAnchor),
            ],
            animatable: [previewTransformedBoundingView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor)]
        )
    }

    private func setupAccessoryViewIfNeeded(
        alignment: Alignment
    ) -> FixedAndAnimatableConstraints {
        guard let accessoryView else { return .empty }

        view.addSubview(accessoryView)
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        return FixedAndAnimatableConstraints(
            fixed: [
                accessoryView.bottomAnchor.constraint(
                    equalTo: previewTransformedBoundingView.topAnchor, constant: -style.preview.topMargin
                ).priority(.required - 1),
                alignment == .leading ?
                    accessoryView.leadingAnchor.constraint(equalTo: previewTransformedBoundingView.leadingAnchor).priority(.defaultHigh)
                    : accessoryView.trailingAnchor.constraint(equalTo: previewTransformedBoundingView.trailingAnchor).priority(.defaultHigh)
            ],
            animatable: NSLayoutConstraint.keeping(view: accessoryView, insideFrameOf: view)
        )
    }
    private func setupMenuViewIfNeeded(
        alignment: Alignment
    ) -> FixedAndAnimatableConstraints {
        guard let menuConfiguration, !menuConfiguration.menu.children.isEmpty else { return .empty }

        let menuView = MenuView(
            menu: menuConfiguration.menu,
            anchorPointAlignment: alignment,
            style: style.menu,
            delegate: self
        )
        self.menuView = menuView
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)

        return FixedAndAnimatableConstraints(
            fixed: [
                menuView.topAnchor.constraint(
                    equalTo: previewTransformedBoundingView.bottomAnchor, constant: style.preview.bottomMargin
                ),
                alignment == .leading ?
                    menuView.leadingAnchor.constraint(equalTo: previewTransformedBoundingView.leadingAnchor).priority(.defaultHigh)
                    : menuView.trailingAnchor.constraint(equalTo: previewTransformedBoundingView.trailingAnchor).priority(.defaultHigh)
            ],
            animatable: NSLayoutConstraint.keeping(view: menuView, insideFrameOf: view)
        )
    }
}

extension ContextMenuViewController {
    private struct FixedAndAnimatableConstraints {
        let fixed: [NSLayoutConstraint]
        let animatable: [NSLayoutConstraint]

        static let empty = FixedAndAnimatableConstraints(fixed: [], animatable: [])
    }
}

extension ContextMenuViewController {
    private func menuAndAccessoryViewAlignment() -> Alignment {
        return baseFrameInScreen.midX > view.bounds.midX ? .trailing : .leading
    }
}

extension ContextMenuViewController {
    @objc private func onTouchUpInsideBackground(_ sender: Any?) {
        delegate?.dismissContextMenuViewController(self, interaction: self.interaction, uponTapping: nil)
    }
}

extension ContextMenuViewController: MenuViewDelegate {
    func dismissMenuView(menuView: MenuView, uponTapping menuElement: MenuElement) {
        delegate?.dismissContextMenuViewController(self, interaction: interaction, uponTapping: menuElement)
    }
}

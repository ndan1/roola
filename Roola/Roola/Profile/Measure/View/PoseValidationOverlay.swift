//
//  PoseValidationOverlay.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import UIKit

class PoseValidationOverlay: UIView {

    // MARK: - UI Components
    private let feedbackLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 32)
        l.textColor = .white
        l.backgroundColor = UIColor(AppColors.primaryPurple).withAlphaComponent(0)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.layer.cornerRadius = 30
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let borderIndicator: UIView = {
        let v = UIView()
        v.layer.borderWidth = 5
        v.layer.borderColor = UIColor.clear.cgColor
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 128, weight: .bold)
        l.textColor = UIColor(AppColors.primaryWhite)
        l.textAlignment = .center
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let stencilImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.alpha = 0
        return iv
    }()

    // Back button
    var onBackTapped: (() -> Void)?
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(btnTouchDown), for: .touchDown)
        b.addTarget(self, action: #selector(btnTouchUp),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return b
    }()

    // MARK: - Init
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        addSubview(stencilImageView)
        addSubview(borderIndicator)
        addSubview(feedbackLabel)
        addSubview(countLabel)
        addSubview(backButton)

        NSLayoutConstraint.activate([
            // Stencil (kept visible)
            stencilImageView.topAnchor.constraint(equalTo: topAnchor),
            stencilImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stencilImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stencilImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Border
            borderIndicator.topAnchor.constraint(equalTo: topAnchor),
            borderIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Feedback (top)
            feedbackLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0),
            feedbackLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.65),
            feedbackLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            // Countdown / Recording – centre
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Back button
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Only back button receives touches
        [stencilImageView, feedbackLabel, borderIndicator].forEach { $0.isUserInteractionEnabled = false }
    }

    // MARK: - Public API
    func showFeedback(_ msg: String, color: UIColor = UIColor(AppColors.primaryPurple)) {
        DispatchQueue.main.async { [weak self] in
            UIView.transition(with: self?.feedbackLabel ?? UIView(),
                              duration: 0.2,
                              options: .transitionCrossDissolve) {
                self?.feedbackLabel.text = msg
                self?.feedbackLabel.backgroundColor = color
            }
        }
    }

    func showValidPoseIndicator(_ valid: Bool) {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.borderIndicator.layer.borderColor = valid ?
                    UIColor.systemGreen.cgColor : UIColor.clear.cgColor
            }
        }
    }

    func setStencil(image: UIImage?, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let work = {
                self.stencilImageView.image = image
                self.stencilImageView.alpha = image == nil ? 0 : 1
            }
            if animated { UIView.animate(withDuration: 0.25, animations: work) } else { work() }
        }
    }

    // MARK: - Countdown (3 → 2 → 1 → Recording…) -------------------------------------------------
    func startCountdown(completion: @escaping () -> Void) {
        // Reset label
        countLabel.text = "3"
        countLabel.font = UIFont.systemFont(ofSize: 140, weight: .bold)
        countLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        countLabel.alpha = 0

        // Fade-in + scale-in
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8,
                       options: [], animations: {
            self.countLabel.alpha = 1
            self.countLabel.transform = .identity
        }) { _ in
            self.runStep(2, completion: completion)
        }
    }

    private func runStep(_ step: Int, completion: @escaping () -> Void) {
        guard step > 0 else {
            self.hideCountLabel {
                completion()
            }
            return
        }

        countLabel.text = "\(step)"
        countLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.8, options: [], animations: {
            self.countLabel.transform = .identity
        }) { _ in
            // 1-second pause before next number
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.runStep(step - 1, completion: completion)
            }
        }
    }
    private func hideCountLabel(completion: @escaping () -> Void) {
        countLabel.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.3, animations: {
            self.countLabel.alpha = 0
            self.countLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        }) { _ in
            completion()
        }
    }

    // MARK: - Success Close Animation -------------------------------------------------
    func showSuccessCloseAnimation(completion: (() -> Void)? = nil) {
        let flash = UIView(frame: bounds)
        flash.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.45)
        flash.alpha = 0
        addSubview(flash)

        UIView.animate(withDuration: 0.25, animations: {
            flash.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.8, options: [], animations: {
                flash.alpha = 0
                flash.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
            }) { _ in
                flash.removeFromSuperview()
                completion?()
            }
        }
    }

    // MARK: - Back button -------------------------------------------------
    @objc private func btnTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }

    @objc private func btnTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.backButton.transform = .identity
        }
        print("BACK BUTTON TAPPED!")
        onBackTapped?()
    }

    // MARK: - Hit-test (only back button)
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let p = convert(point, to: backButton)
        if backButton.bounds.contains(p) {
            return backButton.hitTest(p, with: event)
        }
        return nil
    }
}

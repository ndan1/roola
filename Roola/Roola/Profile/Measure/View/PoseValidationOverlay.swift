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
        l.font = UIFont(name: "HelveticaNeue-Bold", size: 28)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 1
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 3
        l.layer.shadowOpacity = 0.5
        l.layer.shadowOffset = CGSize(width: 0, height: 2)
        return l
    }()

    private let borderIndicator: UIView = {
        let v = UIView()
        v.layer.borderWidth = 6
        v.layer.borderColor = UIColor.clear.cgColor
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 140, weight: .bold)
        l.textColor = UIColor(AppColors.primaryWhite)
        l.textAlignment = .center
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowRadius = 4
        l.layer.shadowOpacity = 0.4
        l.layer.shadowOffset = CGSize(width: 0, height: 2)
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

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left.circle.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = UIColor(AppColors.primaryWhite)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(btnTouchDown), for: .touchDown)
        b.addTarget(self, action: #selector(btnTouchUp),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
        b.alpha = 0.8
        return b
    }()

    // MARK: - Properties
    var onBackTapped: (() -> Void)?
    private var isCountdownActive = false

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
            stencilImageView.topAnchor.constraint(equalTo: topAnchor),
            stencilImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stencilImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stencilImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            borderIndicator.topAnchor.constraint(equalTo: topAnchor),
            borderIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),

            feedbackLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            feedbackLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 18),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        [stencilImageView, feedbackLabel, borderIndicator].forEach { $0.isUserInteractionEnabled = false }
    }

    // MARK: - Helper Methods
    func showFeedback(_ msg: String) {
        DispatchQueue.main.async { [weak self] in
            if self?.feedbackLabel.text == msg { return }
            UIView.transition(with: self?.feedbackLabel ?? UIView(), duration: 0.2, options: .transitionCrossDissolve) {
                self?.feedbackLabel.text = msg
            }
        }
    }

    func showValidPoseIndicator(_ valid: Bool) {
        DispatchQueue.main.async { [weak self] in
            let color = valid ? UIColor.systemGreen.cgColor : UIColor.clear.cgColor
            if self?.borderIndicator.layer.borderColor != color {
                UIView.animate(withDuration: 0.3) {
                    self?.borderIndicator.layer.borderColor = color
                }
            }
        }
    }

    func setStencil(image: UIImage?, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.stencilImageView.image == image { return }
            let work = {
                self.stencilImageView.image = image
                self.stencilImageView.alpha = image == nil ? 0 : 1
            }
            if animated { UIView.animate(withDuration: 0.25, animations: work) } else { work() }
        }
    }

    // MARK: - Countdown Logic (Fixed for Speed)
    
    func startCountdown(completion: @escaping () -> Void) {
        isCountdownActive = true
        countLabel.layer.removeAllAnimations()
        countLabel.alpha = 0
        countLabel.transform = .identity
        animateCountdownStep(3, completion: completion)
    }

    func cancelCountdown() {
        isCountdownActive = false
        DispatchQueue.main.async { [weak self] in
            self?.countLabel.layer.removeAllAnimations()
            self?.countLabel.alpha = 0
        }
    }

    private func animateCountdownStep(_ number: Int, completion: @escaping () -> Void) {
        guard isCountdownActive else { return }

        // 1. Setup
        countLabel.text = "\(number)"
        countLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        countLabel.alpha = 0
        
        // 2. Animate IN
        UIView.animate(withDuration: 0.3, // Faster (was 0.4)
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            self.countLabel.alpha = 1
            self.countLabel.transform = .identity
        }) { _ in
            guard self.isCountdownActive else { return }
            
            // CRITICAL CHANGE FOR "INSTANT" FEEL:
            // If this was number "1", trigger the completion (Photo) NOW.
            // Don't wait for the fade out to finish.
            if number == 1 {
                completion()
            }
            
            // 3. Animate OUT
            UIView.animate(withDuration: 0.2, // Faster (was 0.25)
                           delay: 0.2,        // Shorter hold (was 0.25)
                           options: .curveEaseIn,
                           animations: {
                self.countLabel.alpha = 0
                self.countLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }) { _ in
                guard self.isCountdownActive else { return }
                
                if number > 1 {
                    self.animateCountdownStep(number - 1, completion: completion)
                }
            }
        }
    }

    // MARK: - Success Close Animation
    func showSuccessCloseAnimation(completion: (() -> Void)? = nil) {
        let flash = UIView(frame: bounds)
        flash.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.45)
        flash.alpha = 0
        addSubview(flash)

        UIView.animate(withDuration: 0.2, animations: {
            flash.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.8, options: [], animations: {
                flash.alpha = 0
                flash.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
            }) { _ in
                flash.removeFromSuperview()
                completion?()
            }
        }
    }

    // MARK: - Actions
    @objc private func btnTouchDown() {
        UIView.animate(withDuration: 0.1) { self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }
    }
    @objc private func btnTouchUp() {
        UIView.animate(withDuration: 0.1) { self.backButton.transform = .identity }
        onBackTapped?()
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let p = convert(point, to: backButton)
        if backButton.bounds.contains(p) { return backButton.hitTest(p, with: event) }
        return nil
    }
}

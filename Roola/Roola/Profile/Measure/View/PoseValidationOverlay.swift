//
//  PoseValidationOverlay.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import UIKit
import Vision

class PoseValidationOverlay: UIView {

    // MARK: - UI Components
    private let feedbackLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "HelveticaNeue-Bold", size: 28)
        l.textColor = UIColor(AppColors.primaryWhite)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
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
        b.backgroundColor = UIColor(AppColors.primaryPurple)
        b.layer.cornerRadius = 25
        
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.3
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.layer.shadowRadius = 5

        b.layer.masksToBounds = false
        
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(btnTouchDown), for: .touchDown)
        b.addTarget(self, action: #selector(btnTouchUp),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return b
    }()
    
    // MARK: - Skeleton Layers
    private let skeletonLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor
        l.lineWidth = 3.0
        l.fillColor = UIColor.clear.cgColor
        l.lineCap = .round
        l.lineJoin = .round
        return l
    }()
    
    private let jointsLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        // Default to system purple if AppColors fails, but tries to use your theme
        l.fillColor = UIColor(AppColors.primaryPurple).cgColor
        l.strokeColor = UIColor.white.cgColor
        l.lineWidth = 2.0
        return l
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

        // Add skeleton layers first so they are behind labels but above camera
        layer.addSublayer(skeletonLayer)
        layer.addSublayer(jointsLayer)

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
            feedbackLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            feedbackLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 22),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        [stencilImageView, feedbackLabel, borderIndicator].forEach { $0.isUserInteractionEnabled = false }
    }
    
    // MARK: - Skeleton Drawing
    
    // In PoseValidationOverlay.swift
    func updateSkeleton(points: [VNHumanBodyPoseObservation.JointName : CGPoint]) {
        // Disable implicit animations for instant updates
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 1. Draw Bones
        let path = UIBezierPath()
        
        // Defined connections including legs
        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            // Arms
            (.leftWrist, .leftElbow), (.leftElbow, .leftShoulder),
            (.rightWrist, .rightElbow), (.rightElbow, .rightShoulder),
            
            // Torso (Stop at Neck, do not go to Nose/Eyes)
            (.leftShoulder, .neck), (.rightShoulder, .neck),
            (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.root, .neck), // Spine
            
            // Legs (ADDED)
            (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
            (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
        ]
        
        for (startName, endName) in connections {
            if let start = points[startName], let end = points[endName] {
                path.move(to: start)
                path.addLine(to: end)
            }
        }
        skeletonLayer.path = path.cgPath
        
        // 2. Draw Joints
        let dotsPath = UIBezierPath()
        let radius: CGFloat = 5.0
        
        for (_, point) in points {
            dotsPath.move(to: CGPoint(x: point.x + radius, y: point.y))
            dotsPath.addArc(withCenter: point, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        jointsLayer.path = dotsPath.cgPath
        
        CATransaction.commit()
    }
    
    func clearSkeleton() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        skeletonLayer.path = nil
        jointsLayer.path = nil
        CATransaction.commit()
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

    // MARK: - Countdown Logic
    
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
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            self.countLabel.alpha = 1
            self.countLabel.transform = .identity
        }) { _ in
            guard self.isCountdownActive else { return }
            if number == 1 {
                completion()
            }
            UIView.animate(withDuration: 0.2,
                           delay: 0.2,
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

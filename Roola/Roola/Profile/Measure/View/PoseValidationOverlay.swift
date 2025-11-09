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
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        label.backgroundColor = UIColor(AppColors.primaryPurple).withAlphaComponent(0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.cornerRadius = 30
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let borderIndicator: UIView = {
        let view = UIView()
        view.layer.borderWidth = 5
        view.layer.borderColor = UIColor.clear.cgColor
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressBar: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.progressTintColor = .systemGreen
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let stencilImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = UIColor.clear
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.alpha = 0
        return iv
    }()
    
    var onBackTapped: (() -> Void)?
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "chevron.left.circle.fill", withConfiguration: config)

        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false

        // Touch-down animation (optional but nice)
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp),   for: [.touchUpInside, .touchUpOutside, .touchCancel])

        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        addSubview(stencilImageView)
        addSubview(backButton)
        addSubview(feedbackLabel)
        
        addSubview(borderIndicator)
        addSubview(progressBar)
        
        NSLayoutConstraint.activate([
            // ----- Image stencil – full screen -----
            stencilImageView.topAnchor.constraint(equalTo: topAnchor),
            stencilImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stencilImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stencilImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            // -------------------------------------

            // border, label, progress … (unchanged)
            borderIndicator.topAnchor.constraint(equalTo: topAnchor),
            borderIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),

            feedbackLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feedbackLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0),
            feedbackLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.65),
            feedbackLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            progressBar.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100),
            progressBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        progressBar.alpha = 0
        
        // Ensure other subviews don't intercept touches
        stencilImageView.isUserInteractionEnabled = false
        feedbackLabel.isUserInteractionEnabled = false
        borderIndicator.isUserInteractionEnabled = false
        progressBar.isUserInteractionEnabled = false
    }
    
    // MARK: - Hit Test Override (to pass through touches except for button)
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let buttonPoint = convert(point, to: backButton)
        if backButton.bounds.contains(buttonPoint) {
            return backButton.hitTest(buttonPoint, with: event)
        }
        return nil
    }
    
    // MARK: - Public Methods
    /// Update feedback message dengan warna background
    func showFeedback(_ message: String, color: UIColor = UIColor(AppColors.primaryPurple)) {
        DispatchQueue.main.async { [weak self] in
            UIView.transition(with: self?.feedbackLabel ?? UIView(),
                            duration: 0.2,
                            options: .transitionCrossDissolve,
                            animations: {
                self?.feedbackLabel.text = message
                self?.feedbackLabel.backgroundColor = color
            })
        }
    }
    
    /// Tampilkan border indicator (hijau = valid, clear = invalid)
    func showValidPoseIndicator(_ isValid: Bool) {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.borderIndicator.layer.borderColor = isValid ?
                    UIColor.systemGreen.cgColor : UIColor.clear.cgColor
            }
        }
    }
    
    /// Update progress bar (0.0 - 1.0)
    func updateProgress(_ progress: Float, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            if progress > 0 {
                UIView.animate(withDuration: 0.2) {
                    self?.progressBar.alpha = 1.0
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self?.progressBar.alpha = 0.0
                }
            }
            
            self?.progressBar.setProgress(progress, animated: animated)
        }
    }
    
    /// Show success animation
    func showSuccessAnimation(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Flash green
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            }) { _ in
                UIView.animate(withDuration: 0.3, animations: {
                    self.backgroundColor = .clear
                }, completion: { _ in
                    completion?()
                })
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

            if animated {
                UIView.animate(withDuration: 0.25, animations: work)
            } else {
                work()
            }
        }
    }

    func hideStencil(animated: Bool = true) { setStencil(image: nil, animated: animated) }
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }

    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.backButton.transform = .identity
        }
        print("BACK BUTTON TAPPED!")          // <-- you will see this
        onBackTapped?()
    }
}

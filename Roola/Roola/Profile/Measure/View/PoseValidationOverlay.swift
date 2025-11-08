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
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.cornerRadius = 10
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
        isUserInteractionEnabled = false

        // 1. Add image stencil first (bottom-most)
        addSubview(stencilImageView)

        // 2. Existing UI
        addSubview(borderIndicator)
        addSubview(feedbackLabel)
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
            feedbackLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            feedbackLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),
            feedbackLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            progressBar.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100),
            progressBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            progressBar.heightAnchor.constraint(equalToConstant: 8)
        ])

        progressBar.alpha = 0
    }
    
    // MARK: - Public Methods
    /// Update feedback message dengan warna background
    func showFeedback(_ message: String, color: UIColor = .systemOrange) {
        DispatchQueue.main.async { [weak self] in
            UIView.transition(with: self?.feedbackLabel ?? UIView(),
                            duration: 0.2,
                            options: .transitionCrossDissolve,
                            animations: {
                self?.feedbackLabel.text = message
                self?.feedbackLabel.backgroundColor = color.withAlphaComponent(0.8)
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
                self.stencilImageView.alpha = image == nil ? 0 : 0.75
            }

            if animated {
                UIView.animate(withDuration: 0.25, animations: work)
            } else {
                work()
            }
        }
    }

    func hideStencil(animated: Bool = true) { setStencil(image: nil, animated: animated) }
}

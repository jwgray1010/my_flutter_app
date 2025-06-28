import UIKit

class KeyboardViewController: UIInputViewController {
    
    private var keyboardView: UIView!
    private var toneIndicatorView: UIView!
    private var toneLabel: UILabel!
    private var toneCircle: UIView!
    private var currentTone: String = "balanced"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
        setupToneIndicator()
        setupKeyLayout()
        
        // Start listening for tone analysis updates
        startToneAnalysisListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadKeyboardSettings()
    }
    
    private func setupKeyboardView() {
        keyboardView = UIView()
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0) // #1E1E1E
        view.addSubview(keyboardView)
        
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupToneIndicator() {
        toneIndicatorView = UIView()
        toneIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        toneIndicatorView.backgroundColor = UIColor.clear
        keyboardView.addSubview(toneIndicatorView)
        
        // Logo image view
        let logoImageView = UIImageView(image: UIImage(named: "logo_icon"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        toneIndicatorView.addSubview(logoImageView)
        
        // Tone circle indicator
        toneCircle = UIView()
        toneCircle.translatesAutoresizingMaskIntoConstraints = false
        toneCircle.backgroundColor = UIColor.systemBlue
        toneCircle.layer.cornerRadius = 6
        toneIndicatorView.addSubview(toneCircle)
        
        // Tone label
        toneLabel = UILabel()
        toneLabel.translatesAutoresizingMaskIntoConstraints = false
        toneLabel.text = "Balanced tone"
        toneLabel.textColor = UIColor.white
        toneLabel.font = UIFont.systemFont(ofSize: 14)
        toneIndicatorView.addSubview(toneLabel)
        
        NSLayoutConstraint.activate([
            toneIndicatorView.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 16),
            toneIndicatorView.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: 16),
            toneIndicatorView.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor, constant: -16),
            toneIndicatorView.heightAnchor.constraint(equalToConstant: 48),
            
            logoImageView.leadingAnchor.constraint(equalTo: toneIndicatorView.leadingAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: toneIndicatorView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 32),
            logoImageView.heightAnchor.constraint(equalToConstant: 32),
            
            toneCircle.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 16),
            toneCircle.centerYAnchor.constraint(equalTo: toneIndicatorView.centerYAnchor),
            toneCircle.widthAnchor.constraint(equalToConstant: 12),
            toneCircle.heightAnchor.constraint(equalToConstant: 12),
            
            toneLabel.leadingAnchor.constraint(equalTo: toneCircle.trailingAnchor, constant: 8),
            toneLabel.centerYAnchor.constraint(equalTo: toneIndicatorView.centerYAnchor),
            toneLabel.trailingAnchor.constraint(lessThanOrEqualTo: toneIndicatorView.trailingAnchor)
        ])
    }
    
    private func setupKeyLayout() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        keyboardView.addSubview(stackView)
        
        // Create keyboard rows
        let row1Keys = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
        let row2Keys = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
        let row3Keys = ["Z", "X", "C", "V", "B", "N", "M"]
        
        let row1 = createKeyRow(keys: row1Keys)
        let row2 = createKeyRow(keys: row2Keys)
        let row3 = createKeyRowWithSpecialKeys(keys: row3Keys)
        let row4 = createBottomRow()
        
        stackView.addArrangedSubview(row1)
        stackView.addArrangedSubview(row2)
        stackView.addArrangedSubview(row3)
        stackView.addArrangedSubview(row4)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: toneIndicatorView.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: keyboardView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: keyboardView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createKeyRow(keys: [String]) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 4
        rowStack.distribution = .fillEqually
        
        for key in keys {
            let button = createKeyButton(title: key, isSpecial: false)
            rowStack.addArrangedSubview(button)
        }
        
        return rowStack
    }
    
    private func createKeyRowWithSpecialKeys(keys: [String]) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 4
        rowStack.distribution = .fill
        
        // Shift key
        let shiftButton = createKeyButton(title: "⇧", isSpecial: true)
        shiftButton.addTarget(self, action: #selector(shiftPressed), for: .touchUpInside)
        rowStack.addArrangedSubview(shiftButton)
        
        // Letter keys
        for key in keys {
            let button = createKeyButton(title: key, isSpecial: false)
            rowStack.addArrangedSubview(button)
        }
        
        // Backspace key
        let backspaceButton = createKeyButton(title: "⌫", isSpecial: true)
        backspaceButton.addTarget(self, action: #selector(backspacePressed), for: .touchUpInside)
        rowStack.addArrangedSubview(backspaceButton)
        
        // Set special key widths
        NSLayoutConstraint.activate([
            shiftButton.widthAnchor.constraint(equalToConstant: 60),
            backspaceButton.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        return rowStack
    }
    
    private func createBottomRow() -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 4
        rowStack.distribution = .fill
        
        // Numbers key
        let numbersButton = createKeyButton(title: "123", isSpecial: true)
        numbersButton.addTarget(self, action: #selector(numbersPressed), for: .touchUpInside)
        rowStack.addArrangedSubview(numbersButton)
        
        // Space bar
        let spaceButton = createKeyButton(title: "space", isSpecial: true)
        spaceButton.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        rowStack.addArrangedSubview(spaceButton)
        
        // Return key
        let returnButton = createKeyButton(title: "⏎", isSpecial: true)
        returnButton.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        rowStack.addArrangedSubview(returnButton)
        
        // Set widths
        NSLayoutConstraint.activate([
            numbersButton.widthAnchor.constraint(equalToConstant: 60),
            returnButton.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        return rowStack
    }
    
    private func createKeyButton(title: String, isSpecial: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: isSpecial ? 14 : 16)
        
        if isSpecial {
            button.backgroundColor = UIColor.systemBlue
        } else {
            button.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        }
        
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray.cgColor
        
        return button
    }
    
    @objc private func keyPressed(_ sender: UIButton) {
        guard let key = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(key.lowercased())
        triggerToneAnalysis()
    }
    
    @objc private func shiftPressed() {
        // Toggle shift state - for now just a placeholder
    }
    
    @objc private func backspacePressed() {
        textDocumentProxy.deleteBackward()
        triggerToneAnalysis()
    }
    
    @objc private func spacePressed() {
        textDocumentProxy.insertText(" ")
        triggerToneAnalysis()
    }
    
    @objc private func returnPressed() {
        textDocumentProxy.insertText("\n")
    }
    
    @objc private func numbersPressed() {
        // Switch to numbers mode - placeholder
    }
    
    private func triggerToneAnalysis() {
        let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterText = textDocumentProxy.documentContextAfterInput ?? ""
        let fullText = beforeText + afterText
        
        if !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Send text to main app for analysis via App Groups
            sendTextForAnalysis(text: fullText)
        }
    }
    
    private func sendTextForAnalysis(text: String) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard") else {
            return
        }
        
        sharedDefaults.set(text, forKey: "current_text")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "analysis_timestamp")
        sharedDefaults.synchronize()
        
        // Notify main app
        NotificationCenter.default.post(name: Notification.Name("UnsaidKeyboardTextAnalysis"), object: nil)
    }
    
    private func startToneAnalysisListener() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForToneAnalysisUpdates()
        }
    }
    
    private func checkForToneAnalysisUpdates() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard") else {
            return
        }
        
        let lastUpdate = sharedDefaults.double(forKey: "tone_analysis_timestamp")
        let currentTime = Date().timeIntervalSince1970
        
        // Check if we have a recent analysis update (within last 2 seconds)
        if currentTime - lastUpdate < 2.0 {
            let tone = sharedDefaults.string(forKey: "dominant_tone") ?? "balanced"
            let confidence = sharedDefaults.double(forKey: "confidence")
            
            updateToneDisplay(tone: tone, confidence: confidence)
        }
    }
    
    private func updateToneDisplay(tone: String, confidence: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentTone = tone
            
            // Update tone circle color based on research-aligned mapping
            var toneColor: UIColor
            switch tone.lowercased() {
            case "green":
                toneColor = UIColor.systemGreen
            case "yellow":
                toneColor = UIColor.systemYellow
            case "red":
                toneColor = UIColor.systemRed
            case "gray":
                toneColor = UIColor.systemGray
            default:
                toneColor = UIColor.systemGray
            }
            
            self.toneCircle.backgroundColor = toneColor
            
            // Update tone label
            let toneLabel = tone.capitalized
            let confidencePercent = Int(confidence * 100)
            self.toneLabel.text = "\(toneLabel) tone (\(confidencePercent)%)"
        }
    }
    
    private func loadKeyboardSettings() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard") else {
            return
        }
        
        let toneAnalysisEnabled = sharedDefaults.bool(forKey: "tone_analysis_enabled")
        // Apply settings to keyboard behavior
        toneIndicatorView.isHidden = !toneAnalysisEnabled
    }
}

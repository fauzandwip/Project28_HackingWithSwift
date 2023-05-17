//
//  ViewController.swift
//  Project28
//
//  Created by Fauzan Dwi Prasetyo on 17/05/23.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    @IBOutlet weak var secret: UITextView!
    @IBOutlet weak var authenticateButton: UIButton!
    
    var password: String?
    var wrongPassword = false
    var passwordTextField = UITextField()
    let showPasswordButton = UIButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        // Remove a keychain item with a specific key
//        let keychainKey = "password"
//        let removed = KeychainWrapper.standard.removeObject(forKey: keychainKey)
//        if removed {
//            print("Keychain item with key \(keychainKey) removed successfully.")
//        } else {
//            print("Failed to remove keychain item with key \(keychainKey).")
//        }

        
        setupUI()
        loadPassword()
        
    }
    
    func setupUI() {
        
        // Navigation Bar
        title = "Nothing to see here"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(lockSecretMessage))
        navigationItem.rightBarButtonItem?.isHidden = true
        
        // UI
        authenticateButton.layer.cornerRadius = 10
        authenticateButton.sizeToFit()
        
        // Notification Center
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notification.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notification.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @IBAction func authenticateTapped(_ sender: Any) {
        let ac = UIAlertController(title: "Select Authentication", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Face ID/Touch ID", style: .default) { [weak self] _ in
            self?.biometricButtonTapped()
        })
        ac.addAction(UIAlertAction(title: "Password", style: .default) { [weak self] _ in
            self?.passwordButtonTapped()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .default))
        
        present(ac, animated: true)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    // Secret Message
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Secret Stuff!"
        navigationItem.rightBarButtonItem?.isHidden = false
        
        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
    }
    
    @objc func lockSecretMessage() {
        saveSecretMessage()
        
        navigationItem.rightBarButtonItem?.isHidden = true
    }
    
    // Biometric
    func biometricButtonTapped() {
        let context = LAContext()
        var error: NSError?
        
        // biometric Face ID & Touch ID
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify Yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device in not configured for biometic authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(ac, animated: true)
        }
    }
    
    // Password
    func passwordButtonTapped() {
        // MARK: - Challenge 2
        
        var title = "Create Password"
        var message: String? = nil
        
        if self.password != nil {
            title = "Type Your Password"
        }
        
        if wrongPassword {
            title = "Wrong Password"
            message = "try again"
        }
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addTextField { textField in
            self.passwordTextField = textField
            
            self.showPasswordButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
            self.showPasswordButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            self.showPasswordButton.addTarget(self, action: #selector(self.showPasswordButtonTapped), for: .touchUpInside)
            
            self.passwordTextField.rightView = self.showPasswordButton
            self.passwordTextField.rightViewMode = .always
            self.passwordTextField.isSecureTextEntry = true

        }
        ac.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let password = ac.textFields?[0].text else { return }
            if let pass = self?.password {
                if pass == password {
                    self?.wrongPassword = false
                    self?.unlockSecretMessage()
                } else {
                    self?.wrongPassword = true
                    self?.passwordButtonTapped()
                }
            } else {
                self?.savePassword(pass: password)
                self?.password = password
                self?.passwordButtonTapped()
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.wrongPassword = false
        })
        
        present(ac, animated: true)
    }
    
    func savePassword(pass: String) {
        KeychainWrapper.standard.set(pass, forKey: "password")
    }
    
    func loadPassword() {
        password = KeychainWrapper.standard.string(forKey: "password")
    }
    
    @objc func showPasswordButtonTapped() {
        passwordTextField.isSecureTextEntry.toggle()
        
        let buttonImage = passwordTextField.isSecureTextEntry ? UIImage(systemName: "eye.fill") : UIImage(systemName: "eye.slash.fill")
        showPasswordButton.setImage(buttonImage, for: .normal)
    }
}


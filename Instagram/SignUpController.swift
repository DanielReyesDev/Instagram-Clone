//
//  ViewController.swift
//  Instagram
//
//  Created by Daniel Reyes Sánchez on 22/07/17.
//  Copyright © 2017 Daniel Reyes Sánchez. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class SignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let plusPhotoButton:UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .scaleAspectFit
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handlePlusPhotoButton), for: .touchUpInside)
        return button
    }()
    
    let emailTextField:UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    let usernameTextField:UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.keyboardType = .default
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    let passwordTextField:UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.keyboardType = .default
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    let signUpButton:UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.lightBlue
        button.layer.cornerRadius = 5
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isEnabled = false
        return button
    }()
    
    
    let alreadyHaveAccountButton:UIButton = {
        let button = UIButton()
        let attributedTitle = NSMutableAttributedString(string: "Already have account?  ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                                                                                         NSForegroundColorAttributeName: UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),
                                                                                  NSForegroundColorAttributeName: UIColor.rbg(17, 154, 237)]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        button.setTitleColor(UIColor.blue, for: UIControlState.normal)
        return button
        
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(plusPhotoButton)
        
        plusPhotoButton.anchor(top: self.view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingRight: 0, paddingBottom: 0, width: 140, height: 140)
        
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        
        
        setupInputFields()
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(top: nil, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 0, width: 0, height: 50)
        
    }
    
    func handleDismiss() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func handleSignUp() {
        
        guard let email = emailTextField.text, email.characters.count > 0 else { return }
        guard let username = usernameTextField.text, username.characters.count > 0 else { return }
        guard let password = passwordTextField.text, password.characters.count > 0 else { return }
        
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if let err = error {
                print("Failed to create user:", err)
                return
            }
            print("user created succesfully", user?.uid ?? "")
            
            
            guard let image = self.plusPhotoButton.imageView?.image else {return}
            guard let imageData = UIImageJPEGRepresentation(image, 0.3) else {return}
            
            let filename = NSUUID().uuidString
            
            FIRStorage.storage().reference().child("profile_images").child(filename).put(imageData, metadata: nil, completion: { (metadata: FIRStorageMetadata?, error:Error?) in
                
                if let error = error {
                    print("Failed to upload profile image:",error)
                    return
                }
                
                
                guard let profileImageUrl = metadata?.downloadURL()?.absoluteString else {return}
                print("Successfully upload profile image:",profileImageUrl)
                
                guard let uid = user?.uid else {return}
                let dictionaryValues = ["username":username,"profileImageUrl":profileImageUrl]
                let values = [uid:dictionaryValues]
                FIRDatabase.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (error:Error?, referece:FIRDatabaseReference) in
                    if let err = error {
                        print("Failed to save user info into db:", err)
                        return
                    }
                    
                    print("Successfully saved user into db")
                    
                    guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else {return}
                    mainTabBarController.setupViewControllers()
                    self.dismiss(animated: true, completion: nil)
                })
            })
            
            
        })
    }
    
    func handlePlusPhotoButton() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            self.plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
            print("Edited Image Size: \(editedImage.size)")
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            self.plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
            print("Original Image Size: \(originalImage.size)")
        }
        
        self.plusPhotoButton.layer.cornerRadius = self.plusPhotoButton.frame.width/2
        self.plusPhotoButton.layer.masksToBounds = true
        self.plusPhotoButton.layer.borderColor = UIColor.black.cgColor
        self.plusPhotoButton.layer.borderWidth = 3
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func handleTextInputChange() {
        let isFormVaild = emailTextField.text?.characters.count ?? 0 > 0 && usernameTextField.text?.characters.count ?? 0 > 0 && passwordTextField.text?.characters.count ?? 0 > 0
        
        if isFormVaild {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = .darkBlue
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = .lightBlue
        }
    }
    
    fileprivate func setupInputFields() {
        
        
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, signUpButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        
        stackView.anchor(top: plusPhotoButton.bottomAnchor,
                         left: self.view.leftAnchor,
                         bottom: nil,
                         right: self.view.rightAnchor,
                         paddingTop: 20, paddingLeft: 40,
                         paddingRight: 40,
                         paddingBottom:  0,
                         width: 0,
                         height: 200)
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}








































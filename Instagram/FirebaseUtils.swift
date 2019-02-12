//
//  FirebaseUtils.swift
//  Instagram
//
//  Created by Daniel Reyes Sánchez on 17/09/17.
//  Copyright © 2017 Daniel Reyes Sánchez. All rights reserved.
//

import Foundation
import Firebase


extension FIRDatabase {
    static func fetchUserWithUID(uid: String, completion: @escaping (User) -> () ) {
        print("fetching user with uid: ",uid)
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot:FIRDataSnapshot) in
            print("success")
            guard let userDictionary = snapshot.value as? [String:Any] else {return}
            let user = User(uid:uid, dictionary:userDictionary)
            
            completion(user)
            
        }) { (err:Error) in
            print("Failed")
        }
    }
}

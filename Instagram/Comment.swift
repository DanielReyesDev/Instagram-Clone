//
//  Comment.swift
//  Instagram
//
//  Created by Daniel Reyes Sánchez on 26/09/17.
//  Copyright © 2017 Daniel Reyes Sánchez. All rights reserved.
//

import Foundation


struct Comment {
    let text:String
    let uid:String
    let user:User
    
    init(user:User, dictionary: [String:Any]) {
        self.text = dictionary["text"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.user = user
    }
}

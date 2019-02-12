//
//  UserProfileController.swift
//  Instagram
//
//  Created by Daniel Reyes Sánchez on 19/08/17.
//  Copyright © 2017 Daniel Reyes Sánchez. All rights reserved.
//

import UIKit
import Firebase

class UserProfileController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UserProfileHeaderDelegate {
    
    var user: User?
    var posts = [Post]()
    var userId: String?
    
    let headerId = "headerId"
    let cellId = "cellId"
    let listCellId = "listCellId"
    
    var isGridView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white
        
        fetchUser()
        setupCollectionView()
        setupLogoutButton()
        
        
    }
    
    
//    fileprivate func fetchPosts() {
//        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
//        let ref = FIRDatabase.database().reference().child("posts").child(uid)
//        ref.observeSingleEvent(of: .value, with: { (snapshot:FIRDataSnapshot) in
//            guard let dicitonaries = snapshot.value as? [String:Any] else {return}
//            dicitonaries.forEach({ (key:String,value:Any) in
//                guard let dictionary = value as? [String:Any] else {return}
//                self.posts.append(Post(user: self.user, dictionary:dictionary))
//            })
//            DispatchQueue.main.async {
//                self.collectionView?.reloadData()
//            }
//        }) { (error:Error) in
//            print("Error: ",error.localizedDescription)
//        }
//    }
    
    
    var isFinishedPaging = false
    
    fileprivate func paginatesPosts() {
        print("Start paging for more posts")
        guard let uid = self.user?.uid else { return }
        let ref = FIRDatabase.database().reference().child("posts").child(uid)
        //var query = ref.queryOrderedByKey()
        var query = ref.queryOrdered(byChild: "creationDate")
        if posts.count > 0 {
            let value = posts.last?.creationDate.timeIntervalSince1970 // con referencia al tiempo
            query = query.queryEnding(atValue: value) // para comenzar a hacer el fetch desde abajo hacia arriba
        }
        query.queryLimited(toLast: 4).observe(.value, with: { (snapshot) in
            guard var allObjects = snapshot.children.allObjects as? [FIRDataSnapshot] else {return}
            allObjects.reverse()
            if allObjects.count < 4 {
                self.isFinishedPaging = true
            }
            if self.posts.count > 0 && allObjects.count > 0 {
                allObjects.removeFirst()
            }
            guard let user = self.user else {return}
            allObjects.forEach({ (snapshot) in
                guard let dictionary = snapshot.value as? [String:Any] else {return}
                var post = Post(user: user, dictionary: dictionary)
                post.id = snapshot.key
                self.posts.append(post)
            })
            
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }) { (error) in
            print("Error: ", error.localizedDescription)
        }
    }
    
    fileprivate func fetchOrderedPosts() {
        guard let uid = self.user?.uid else { return }
        let ref = FIRDatabase.database().reference().child("posts").child(uid)
        // getting the data in the same order that it was inserted and OBSERVE when a new insertion occurs
        ref.queryOrdered(byChild: "creationDate").observe(.childAdded, with: { (snapshot:FIRDataSnapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else {return}
            guard let user = self.user else {return}
            self.posts.insert(Post(user: user, dictionary: dictionary), at: 0)
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }) { (err:Error) in
            
        }
    }
    
    
    
    fileprivate func setupCollectionView() {
        self.collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerId)
        self.collectionView?.register(UserProfilePhotoCell.self , forCellWithReuseIdentifier: cellId)
        self.collectionView?.register(HomePostCell.self , forCellWithReuseIdentifier: listCellId)
    }
    
    
    
    fileprivate func fetchUser(){
        
        let uid = userId ?? (FIRAuth.auth()?.currentUser?.uid ?? "")
        print("Current UID: \(uid)")
        //guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.fetchUserWithUID(uid: uid) { (user) in
            self.user = user
            self.navigationItem.title = self.user?.username
            self.collectionView?.reloadData()
            //self.fetchOrderedPosts()
            self.paginatesPosts()
        }
        
    }
    
    
    fileprivate func setupLogoutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
    }
    
    
    func didChangeToListView() {
        print("Changed to list view")
        isGridView = false
        self.collectionView?.reloadData()
    }
    
    func didChangeToGridView() {
        print("Changed to grid view")
        isGridView = true
        self.collectionView?.reloadData()
    }
    
    
    func handleLogout() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            print("log out")
            do {
                try FIRAuth.auth()?.signOut()
                
                let vc = LoginController()
                let nav = UINavigationController(rootViewController: vc)
                self.present(vc, animated: true, completion: nil)
                
            } catch let error {
                print(error.localizedDescription)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Firing off the paginate call
        if indexPath.item == self.posts.count - 1 && !self.isFinishedPaging{
            paginatesPosts()
        }
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
            cell.post = self.posts[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: listCellId, for: indexPath) as! HomePostCell
            cell.post = self.posts[indexPath.item]
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isGridView {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            var height:CGFloat = 56 // username and userprofileimageview
            height += view.frame.width // square photo
            height += 50 // action buttons
            height += 60 // caption
            return CGSize(width: view.frame.width, height: height)
        }
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! UserProfileHeader
        header.user = self.user
        header.delegate = self
        return header
    }
}

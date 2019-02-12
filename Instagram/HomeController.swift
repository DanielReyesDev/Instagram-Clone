//
//  HomeController.swift
//  Instagram
//
//  Created by Daniel Reyes Sánchez on 17/09/17.
//  Copyright © 2017 Daniel Reyes Sánchez. All rights reserved.
//

import UIKit
import Firebase

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate {
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationItems()
        setupObservers()
        fetchAllPosts()
        setupRefreshControl()
    }
    fileprivate func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoController.updateFeedNotificationName, object: nil)
    }
    
    func handleUpdateFeed() {
        handleRefresh()
    }
    
    fileprivate func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
    }
    
    func handleRefresh() {
        print("Handling refresh...")
        posts.removeAll()
        fetchAllPosts()
    }
    
    fileprivate func fetchAllPosts() {
        fetchPosts()
        fetchFollowingUserIds()
    }
    
    fileprivate func fetchFollowingUserIds() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        FIRDatabase.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String:Any] else {return}
            userIdsDictionary.forEach({ (key,value) in
                FIRDatabase.fetchUserWithUID(uid: key, completion: { (user) in
                    self.fetchPostsWithUser(user)
                })
            })
            
        }) { (error) in
            print("Failed to fetch following users", error.localizedDescription)
        }
    }
    
    fileprivate func setupView() {
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self , forCellWithReuseIdentifier: cellId)
    }
    
    fileprivate func setupNavigationItems() {
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo2"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
    }
    
    func handleCamera() {
        let vc = CameraController()
        present(vc, animated: true, completion: nil)
    }
    
    var posts = [Post]()
    fileprivate func fetchPosts() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.fetchUserWithUID(uid: uid) { (user) in
            self.fetchPostsWithUser(user)
        }
    }
    
    fileprivate func fetchPostsWithUser(_ user:User) {
        let ref = FIRDatabase.database().reference().child("posts").child(user.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot:FIRDataSnapshot) in
            self.collectionView?.refreshControl?.endRefreshing() // Sólo disponible en iOS 10+
            guard let dicitonaries = snapshot.value as? [String:Any] else {return}
            dicitonaries.forEach({ (key:String,value:Any) in
                guard let dictionary = value as? [String:Any] else {return}
                var post = Post(user: user, dictionary:dictionary)
                post.id = key
                guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
                FIRDatabase.database().reference().child("likes").child(key).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? Int, value == 1 {
                        post.hasLiked = true
                    } else {
                        post.hasLiked = false
                    }
                    self.posts.append(post)
                    self.posts.sort(by: { return $0.creationDate.compare($1.creationDate) == .orderedDescending })
                    DispatchQueue.main.async { self.collectionView?.reloadData() }
                }, withCancel: { (error) in
                    print("Failed fetching likes:",error.localizedDescription)
                })
            })
            
        }) { (error:Error) in
            print("Error: ",error.localizedDescription)
        }
    }
    
    // Comment delegate
    func didTapComment(post: Post) {
        print("Comment from post: \(post.caption)")
        let vc = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        vc.post = post
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didLike(for cell: HomePostCell) {
        print("Handling like inside of controller")
        guard let indexPath = collectionView?.indexPath(for: cell) else {return}
        var post = self.posts[indexPath.item]
        print(post.caption)
        guard let postId = post.id else {return}
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        let values = [uid: post.hasLiked == true ? 0 : 1]
        FIRDatabase.database().reference().child("likes").child(postId).updateChildValues(values) { (error, _) in
            if let error = error {
                print("Failed to like post:",error)
                return
            }
            print("Successfully liked to post")
            post.hasLiked = !post.hasLiked
            self.posts[indexPath.item] = post
            self.collectionView?.reloadItems(at: [indexPath])
        }
    }
    
    
    
    // CollectionView Delegate Methods
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        cell.delegate = self
        cell.post = self.posts[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height:CGFloat = 56 // username and userprofileimageview
        height += view.frame.width // square photo
        height += 50 // action buttons
        height += 60 // caption
        
        return CGSize(width: view.frame.width, height: height )
    }
    
}

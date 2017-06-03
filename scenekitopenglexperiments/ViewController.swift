//
//  ViewController.swift
//  scenekitopenglexperiments
//
//  Created by Stanley Chiang on 6/3/17.
//  Copyright © 2017 Stanley Chiang. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {

    lazy var sphereSceneView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsCameraControl = true
        view.showsStatistics = true
//        view.tag = 0
        view.isHidden = false
        return view
    }()
    
    lazy var extractedSceneView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsCameraControl = true
        view.showsStatistics = true
        view.alpha = 0.5
//        view.tag = 1
        view.isHidden = true
        return view
    }()
    
    var activeSceneView:SCNView?
//    var activeSceneTag:Int?
    
    lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.backgroundColor = UIColor.orange
        button.setTitle("Add more Points", for: UIControlState.disabled)
        button.setTitle("Switch View", for: UIControlState.normal)
        return button
    }()
    
//        http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/
    lazy var sphereScene:SCNScene = {

        guard let imagePath = Bundle.main.path(forResource: "Hellbrunn25", ofType: "jpg") else {
            fatalError("Failed to find path for panaromic file.")
        }
        guard let image = UIImage(contentsOfFile:imagePath) else {
            fatalError("Failed to load panoramic image")
        }
        let scene = SCNScene()
        
        let sphere = SCNSphere(radius: 20.0)
        sphere.firstMaterial!.isDoubleSided = true
        sphere.firstMaterial!.diffuse.contents = image
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3Make(0,0,0)
        scene.rootNode.addChildNode(sphereNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }()
    
    lazy var extractedScene:SCNScene = {
        
        guard let imagePath = Bundle.main.path(forResource: "Hellbrunn25", ofType: "jpg") else {
            fatalError("Failed to find path for panaromic file.")
        }
        guard let image = UIImage(contentsOfFile:imagePath) else {
            fatalError("Failed to load panoramic image")
        }
        let scene = SCNScene()
        
        let sphere = SCNSphere(radius: 20.0)
        sphere.firstMaterial!.isDoubleSided = true
        sphere.firstMaterial!.diffuse.contents = image
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3Make(0,0,0)
        scene.rootNode.addChildNode(sphereNode)
        
        return scene
    }()
    
    lazy var tapGestRec:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler(sender:)))
    
    var markedPoints:[SCNNode] = [SCNNode]() {
        didSet {
            if markedPoints.count == 4 {
                toggleButton.isEnabled = true
            }
            
            if markedPoints.count > 4 {
                markedPoints.removeFirst().removeFromParentNode()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sphereSceneView.scene = sphereScene
        extractedSceneView.scene = extractedScene
        
        self.view.addSubview(extractedSceneView)
        self.view.addSubview(sphereSceneView)
        
//        activeSceneTag = 0
        
        activeSceneView = sphereSceneView
//        if let activeView = activeSceneView {
//            self.view.addSubview(activeView)
//        }
        
        self.view.addGestureRecognizer(tapGestRec)
        
        self.view.addSubview(toggleButton)
        toggleButton.addTarget(self, action: #selector(toggleHandler(sender:)), for: UIControlEvents.touchUpInside)
    }

    ///the gesture to handle convert the cgpoint tap location to the location in the 360 sphere
    func tapHandler(sender: UITapGestureRecognizer) {
        guard let activeView = activeSceneView else {
            fatalError("No active scene")
        }
        
        guard activeView == sphereSceneView else {
            print("marks can only be added to the sphere scene; you are not on the sphere scene")
            return
        }
        
//        guard let tag = activeSceneTag else {
//            fatalError("No active scene tag")
//        }
//        
//        guard tag == 0 else {
//            print("marks are only allowed on the sphere view")
//            return
//        }
        
        let point2d = sender.location(in: self.view)
        print(point2d)
        
        var hitResults:[SCNHitTestResult] = activeView.hitTest(point2d, options: nil)
        
        if let result = hitResults.first {
            markPoint(on: result.node, at: result.localCoordinates)
        }
    }
    
    
    ///adds point to 360 image
    func markPoint(on sphere:SCNNode, at point3d:SCNVector3) {
        let mark = SCNSphere(radius: 0.2)
        mark.firstMaterial?.diffuse.contents = UIColor.cyan
        
        let markerNode = SCNNode(geometry: mark)
        markerNode.position = point3d
        sphere.addChildNode(markerNode)
        markedPoints.append(markerNode)
        print(markerNode.position)
    }
    
    ///toggles between the 360 sphere and the scene that will contain the outputed texture
    func toggleHandler(sender: UIButton) {
        
        guard let activeView = activeSceneView else {
            fatalError("No active scene")
        }
        
//        guard let tag = activeSceneTag else {
//            fatalError("No active scene tag")
//        }
        
        print("swap scenes")
        
//        if activeView == sphereSceneView {
            sphereSceneView.isHidden = !sphereSceneView.isHidden
            extractedSceneView.isHidden = !extractedSceneView.isHidden
//        } else if activeView == extractedSceneView {
//            sphereSceneView.isHidden = !sphereSceneView.isHidden
//            extractedSceneView.isHidden = !extractedSceneView.isHidden
//        }
        
//        self.view.viewWithTag(0)?.isHidden = !(self.view.viewWithTag(0)?.isHidden)!
//        self.view.viewWithTag(1)?.isHidden = !(self.view.viewWithTag(1)?.isHidden)!

//        if tag == 0 {
//            activeSceneTag = 1
//        } else {
//            activeSceneTag = 0
//        }
        
        
//        print(activeSceneView!.tag)
//        if activeView.tag == 0 {
//            activeSceneView = extractedSceneView
//            reloadInputViews()
//            print(activeSceneView!.tag)
//        } else {
//            activeSceneView = sphereSceneView
//            reloadInputViews()
//            print(activeSceneView!.tag)
//        }
        
        
    }
    
    override func viewWillLayoutSubviews() {
//        if let activeView = activeSceneView {
//            activeView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
//            activeView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
//            activeView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
//            activeView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
//        }
        
        sphereSceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        sphereSceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        sphereSceneView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        sphereSceneView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        
        extractedSceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        extractedSceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        extractedSceneView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        extractedSceneView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
}

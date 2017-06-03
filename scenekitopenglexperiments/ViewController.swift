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

    lazy var sceneView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsCameraControl = true
        view.showsStatistics = true
        return view
    }()
    
    lazy var scene:SCNScene = {
//        http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(sceneView)
        sceneView.scene = scene
        
        
        
    }

    override func viewWillLayoutSubviews() {
        sceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        sceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        sceneView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
    }
}


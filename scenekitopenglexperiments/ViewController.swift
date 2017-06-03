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

//        http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/
    lazy var scene:SCNScene = {

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
    
//    lazy var sphere: SCNSphere = {
//        guard let imagePath = Bundle.main.path(forResource: "Hellbrunn25", ofType: "jpg") else {
//            fatalError("Failed to find path for panaromic file.")
//        }
//        guard let image = UIImage(contentsOfFile:imagePath) else {
//            fatalError("Failed to load panoramic image")
//        }
//        
//        let sphere = SCNSphere(radius: 20.0)
//        sphere.firstMaterial!.isDoubleSided = true
//        sphere.firstMaterial!.diffuse.contents = image
//        
//        return sphere
//    }()
//    
//    lazy var sphereNode: SCNNode = {
//        let node = SCNNode(geometry: sphere)
//        node.position = SCNVector3Make(0,0,0)
//        scene.rootNode.addChildNode(node)
//        
//        return node
//    }()
    
    var markedPoints = [SCNVector3]()
    
    var tapGestRec = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(sceneView)
        sceneView.scene = scene
        
        tapGestRec.addTarget(self, action: #selector(tapHandler(sender:)))
        self.view.addGestureRecognizer(tapGestRec)
    }

    func tapHandler(sender: UITapGestureRecognizer) {
        let point2d = sender.location(in: self.view)
        print(point2d)
        
        let hitResults:[SCNHitTestResult] = sceneView.hitTest(point2d, options: nil)
        
        if let result = hitResults.first {
            markPoint(on: result.node, at: result.localCoordinates)
        }
    }
    
    func markPoint(on sphere:SCNNode, at point3d:SCNVector3) {
        let mark = SCNSphere(radius: 0.2)
        mark.firstMaterial?.diffuse.contents = UIColor.cyan
        
        let markerNode = SCNNode(geometry: mark)
        markerNode.position = point3d
        markedPoints.append(markerNode.position)
        sphere.addChildNode(markerNode)
        
        print(markerNode.position)
    }
    
    override func viewWillLayoutSubviews() {
        sceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        sceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        sceneView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
    }
    
}


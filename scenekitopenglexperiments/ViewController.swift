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
    
    lazy var activeSceneView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsCameraControl = true
        view.showsStatistics = true
        view.isHidden = false
        return view
    }()
    
    lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.backgroundColor = UIColor.orange
        button.setTitle("Add 4 more Points (Tap on Scene)", for: UIControlState.disabled)
        button.setTitle("Switch to Extracted View", for: UIControlState.normal)
        button.addTarget(self, action: #selector(toggleHandler(sender:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
//        http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/
    lazy var sphereScene:SCNScene = {

        guard let imagePath = Bundle.main.path(forResource: "gallery", ofType: "jpeg") else {
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
        
        guard let imagePath = Bundle.main.path(forResource: "gallery", ofType: "jpeg") else {
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
            if markedPoints.count < 4 {
                toggleButton.setTitle("Add \(4 - markedPoints.count) more Points (Tap on Scene)", for: UIControlState.disabled)
                
                if markedPoints.count > 1 {
                    drawLine(between: markedPoints[markedPoints.count - 1], and: markedPoints[markedPoints.count - 2])
                }
                
                return
            }
            
            if markedPoints.count == 4 {
                toggleButton.isEnabled = true
                drawLine(between: markedPoints[markedPoints.count - 1], and: markedPoints[markedPoints.count - 2])
                drawLine(between: markedPoints[markedPoints.count - 1], and: markedPoints[0])
            } else {
                markedPoints.removeFirst().removeFromParentNode()
            }
            
            extractTexture(from: markedPoints)
        }
    }
    
    func drawLine(between nodeA:SCNNode, and nodeB:SCNNode) {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [nodeA.position, nodeB.position], count: 2)
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        let lineShape = SCNGeometry(sources: [source], elements: [element])
        
        let lineNode = SCNNode(geometry: lineShape)
        
        
        nodeA.parent!.addChildNode(lineNode)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activeSceneView.scene = sphereScene
        self.view.addSubview(activeSceneView)
        
        self.view.addGestureRecognizer(tapGestRec)
        
        self.view.addSubview(toggleButton)
        
    }

    ///the gesture to handle convert the cgpoint tap location to the location in the 360 sphere
    func tapHandler(sender: UITapGestureRecognizer) {
        guard let activeScene = activeSceneView.scene else {
            fatalError("no active scene")
        }

        guard activeScene == sphereScene else {
            print("marks can only be added to the sphere scene; you are not on the sphere scene")
            return
        }
        
        let point2d = sender.location(in: self.view)
        let hitResults:[SCNHitTestResult] = activeSceneView.hitTest(point2d, options: nil)
        
        if let result = hitResults.first {
            markPoint(on: result.node, at: result.localCoordinates)
            print(result.localCoordinates)
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
    }
    
    ///toggles between the 360 sphere and the scene that will contain the outputed texture
    func toggleHandler(sender: UIButton) {
        if let activeScene = activeSceneView.scene {
            if activeScene == sphereScene {
                activeSceneView.scene = extractedScene
                toggleButton.setTitle("Switch to Sphere View", for: UIControlState.normal)
            } else {
                activeSceneView.scene = sphereScene
                toggleButton.setTitle("Switch to Extracted View", for: UIControlState.normal)
            }
        }
    }
    
    func extractTexture(from nodes:[SCNNode]) {
        let processedNodes = classifyCorners(from: nodes)
        
        for (key, node) in processedNodes {
            //set colors for the corners
        }
    }
    
    func classifyCorners(from nodes:[SCNNode]) -> [String:SCNVector3] {
        let positions:[SCNVector3] = nodes.map({($0 as SCNNode).position})
        
        //TODO: implement quickhull to classify corners
        
        let planeDict:[String:SCNVector3] = ["tl":positions[0], "tr":positions[1], "br":positions[2], "bl":positions[3]]
        return planeDict
    }
    
    override func viewWillLayoutSubviews() {
        activeSceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        activeSceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        activeSceneView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        activeSceneView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
}

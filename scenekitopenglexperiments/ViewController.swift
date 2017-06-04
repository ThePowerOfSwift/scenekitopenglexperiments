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
        //TODO: showing the source sphere as done below is only to serve as a placeholder. once we have extracted textures from the sphere scene, we should dump them in this scene
        
        let scene = SCNScene()
        
        
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
                toggleButton.backgroundColor = UIColor.green
                drawLine(between: markedPoints[markedPoints.count - 1], and: markedPoints[markedPoints.count - 2])
                drawLine(between: markedPoints[markedPoints.count - 1], and: markedPoints[0])
                
                extractTexture(from: markedPoints)
                createPlane(with: markedPoints)
            }
            else {
                markedPoints.removeFirst().removeFromParentNode()
                //TODO:update lines for debug visualization purposes only
            }
            
            
        }
    }
    
    func drawLine(between nodeA:SCNNode, and nodeB:SCNNode) {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [nodeA.position, nodeB.position], count: 2)
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        let lineShape = SCNGeometry(sources: [source], elements: [element])
        lineShape.materials.first?.diffuse.contents = UIColor.cyan
        
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
        print(point2d)
        let hitResults:[SCNHitTestResult] = activeSceneView.hitTest(point2d, options: nil)
        
        if let result = hitResults.first {
            markPoint(on: result.node, at: result.localCoordinates)
        }
    }

    ///adds point to 360 image
    func markPoint(on sphere:SCNNode, at point3d:SCNVector3, with color:UIColor = UIColor.cyan) {
        let mark = SCNSphere(radius: 0.3)
        mark.firstMaterial?.diffuse.contents = color
        
        let markerNode = SCNNode(geometry: mark)
        markerNode.position = point3d
        sphere.addChildNode(markerNode)
        
        if markedPoints.count <= 4 {
            markedPoints.append(markerNode)
        }
    }
    
    ///toggles between the 360 sphere and the scene that will contain the outputed texture
    func toggleHandler(sender: UIButton) {
        toggle()
    }
    
    func toggleHandler() {
        toggle()
    }
    
    func toggle(){
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
//        let processedNodes = classifyCorners(from: nodes)
        
        let projectedPoints:[CGPoint] = nodes.map({
            let projPoint = activeSceneView.projectPoint($0.position as SCNVector3)
            let flattenedPoint = CGPoint(x: CGFloat(projPoint.x), y: CGFloat(projPoint.y))
            print(flattenedPoint)
            return flattenedPoint
        })
        
        //FIXME: test edge case - if i set marked points very far away from each other (like on opposite sides of the sphere) the projected points have off screen CGpoint values that are not converted back into 3d properly. we can re-convert these 2d points into 3d space then we can loop through those 2d coordinates grabbing the projected 2d pixels without having to deal with the polar coordinates with the sphere. for example, https://stackoverflow.com/a/26945594/1079379
        // for now it only works if marked points are somewhat close together like if all 4 points are visible at the same time, without needing to adjust the camera
        
//        for point2d in projectedPoints {
//            let hitResults:[SCNHitTestResult] = activeSceneView.hitTest(point2d, options: nil)
//            if let result = hitResults.first {
//                markPoint(on: result.node, at: result.localCoordinates, with: UIColor.red)
//            }
//        }
    }
    
    func createPlane(with nodes:[SCNNode]) {
        let positions:[SCNVector3] = nodes.map({$0.position as SCNVector3})
        let triangles:[[Int32]] = [[0, 1, 2], [2, 3, 0]]
        var elements:[SCNGeometryElement] = [SCNGeometryElement]()
        
        let vertexSource:SCNGeometrySource = SCNGeometrySource(vertices: positions, count: positions.count)
        
        for triangle in triangles {
            elements.append(SCNGeometryElement(indices: triangle, primitiveType: SCNGeometryPrimitiveType.triangles))
        }
        
        let planeShape = SCNGeometry(sources: [vertexSource], elements: elements)
        planeShape.materials.first?.diffuse.contents = UIColor.cyan
        planeShape.materials.first?.isDoubleSided = true
        
        let planeNode = SCNNode(geometry: planeShape)
        planeNode.position = SCNVector3Zero

        extractedScene.rootNode.addChildNode(planeNode)
        
    }
    
    func classifyCorners(from nodes:[SCNNode]) -> [String:SCNVector3] {
        let positions:[SCNVector3] = nodes.map({($0 as SCNNode).position})
        
        //TODO: implement the quickhull for to identification of correct border lines for points to transfer into new texture (tl, tr, etc not actually necessary as long as the corners are sorted such that their edges don't intersect); right now we simply assume that the points are created in a circular manner which doesn't require quickhull
//        https://en.wikipedia.org/wiki/Quickhull
//        https://github.com/utahwithak/QHullSwift
//        https://gist.github.com/adunsmoor/e848356a57980ab9f822
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

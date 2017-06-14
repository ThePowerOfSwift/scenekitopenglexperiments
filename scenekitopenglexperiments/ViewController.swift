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
        view.showsStatistics = true
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
        sphereNode.name = "sphereScene"
        scene.rootNode.addChildNode(sphereNode)
        
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }()
    
    lazy var extractedScene:SCNScene = {
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        return scene
    }()
    
    lazy var tapGestRec:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler(sender:)))
    lazy var lookGestRec:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(lookHandler(gestureRecognizer:)))
    lazy var walkGestRec:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(walkHandler(gestureRecognizer:)))
    
    lazy var elevation: Float = 0
    
    ///planes are stored as an array of vertex array indicies
    var markedPlanes:[[Int]] = [[Int]]() {
        didSet {
            if markedPlanes.last!.count % 4 == 0 {
                let newCompleteSet:[SCNNode] = markedPlanes.last!.map({markedVertices[$0]})
                let texture = extractTexture(from: newCompleteSet)
                let plane = createPlane(with: newCompleteSet)
                applyTexture(from: texture, to: plane)
                
                toggleButton.sendActions(for: .touchUpInside)
            }
        }
    }
    
    ///vertices are stored as a master array of unique nodes
    var markedVertices:[SCNNode] = [SCNNode]() {
        didSet {
            //TODO: we should first check if there already exists a line and only draw a line between nodes that were previously not connected
            
            //FIXME: line drawing is not correct - low priority defect; for visualization only
            //connect new node to previous node when not on the first node of a new plane
//            if markedPlanes[markedPlanes.count - 1].count > 0 {
//                drawLine(between: markedVertices[markedVertices.count - 1], and: markedVertices[markedVertices.count - 2])
//            }
//            
//            //also anchor 4th corner to the first node
//            if markedVertices.count == 4 {
//                drawLine(between: markedVertices[markedVertices.count - 1], and: markedVertices[0])
//            }

            //we need more points to create our first plane
            if markedVertices.count < 4 {
                toggleButton.setTitle("Add \(4 - markedVertices.count) more Points (Tap on Scene)", for: UIControlState.disabled)
            }
            
            if markedVertices.count == 4 {
                toggleButton.isEnabled = true
                toggleButton.backgroundColor = UIColor.green
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
        
        activeSceneView.addGestureRecognizer(tapGestRec)
        activeSceneView.addGestureRecognizer(lookGestRec)
//        activeSceneView.addGestureRecognizer(walkGestRec)
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
        
        //location is directly taken from UIView, and is not tied to any referenced or passed in views
        let point2d = sender.location(in: self.view)
        let hitResults:[SCNHitTestResult] = activeSceneView.hitTest(point2d, options: nil)
        
        parseResults(hitResults: hitResults)
    }
    
    var originalCameraPosition : GLKQuaternion?
    var panStartPoint : CGPoint?
    
    func lookHandler(gestureRecognizer : UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .possible:
            break
            
        case .began:
            panStartPoint = gestureRecognizer.translation(in: self.view)
            beginPanMovement()
            
        case .changed:
            let currentPoint = gestureRecognizer.translation(in: self.view)
            updatePanMovementOffset(x: Float(currentPoint.x - panStartPoint!.x), y: Float(currentPoint.y - panStartPoint!.y))
            
        default:
            endPanMovement()
        }
    }
    
    func beginPanMovement() {
        originalCameraPosition = activeSceneView.scene?.rootNode.childNode(withName: "camera", recursively: false)!.orientation.toGLKQuaternion()
    }
    
    func updatePanMovementOffset(x: Float, y: Float) {
        if let originalPosition = originalCameraPosition {
            let xRadians = x.horizontalOffsetPixelsToRadians(view: self.view)
            let yRadians = y.verticalOffsetPixelsToRadians(view: self.view)
            
            activeSceneView.scene?.rootNode.childNode(withName: "camera", recursively: false)!.orientation = originalPosition.rotateBy(radiansOffsetX: xRadians, radiansOffsetY: yRadians).toSCNQuaternion()
        }
    }
    
    func endPanMovement() {
        originalCameraPosition = nil
    }
    
    func walkHandler(gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.ended || gestureRecognizer.state == UIGestureRecognizerState.cancelled {
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    func parseResults(hitResults: [SCNHitTestResult]) {
        //make sure there's at least 1 result and we assume its the sphere
        guard let firstResult = hitResults.first else {
            fatalError("camera should be inside sphere so taps should always be hitting at least 1 node, not empty space")
        }
        
        //if there are 2 results make sure the second one is the sphere
        if hitResults.count == 2 {
            guard hitResults[1].node.name == "sphereScene" else {
                fatalError("Broken Assumption: we assume that if we hit 2 items the first is always an exsitng marked vertex node and the second is the main sphere scene. but based on the name, the second result is not a sphere")
            }
        } else if hitResults.count > 2 { //more than 2 results
            fatalError("the hittest hit \(hitResults.count) nodes (1 vertex, 1 main sphere). we don't want to support overlapping vertices right now so we will crash the app")
        }
        
        //if we are still identifing our first plane
        if markedVertices.count < 4 {
            //if we just selected our first vertex directly add it to array
            markVertex(on: firstResult.node, at: firstResult.localCoordinates)
            
            //if first plane then we know the index of the first 4 vertices
            if markedPlanes.count == 0 {
                markedPlanes.append([0])
            } else {
                markedPlanes[0].append(markedVertices.count - 1)
            }
        } else { // if there's already at least 1 plane then we have to consider that the user selected an existing node as the corner of a second plane
            //if selected node is an existing node, then add their existing index in the vertex array to the planes array without adding any new vertices
            var nodeIndex:Int?
            
            if let indexOfFoundNode = markedVertices.index(of: firstResult.node) {
                nodeIndex = indexOfFoundNode
            } else { //if selected node is a new vertex on the sphere, then add record it to the array
                
                if hitResults.count == 2 {
                    
                }
                markVertex(on: firstResult.node, at: firstResult.localCoordinates, with: UIColor.purple)
                nodeIndex = markedVertices.count - 1
            }
            
            guard let index = nodeIndex else {
                fatalError("something went wrong with index selection")
            }
            
            //add that index to the plane that is currently being constructed
            if markedPlanes.last!.count % 4 != 0 {
                markedPlanes[markedPlanes.count - 1].append(index)
            } else { //or new node index to the current plane's indicies array or start storing into a new plane
                markedPlanes.append([index])
            }
        }
    }
    
    ///adds point to 360 image
    func markVertex(on sphere:SCNNode, at point3d:SCNVector3, with color:UIColor = UIColor.cyan) {
        let mark = SCNSphere(radius:
//            1)
            0.3)
        mark.firstMaterial?.diffuse.contents = color
        
        let markerNode = SCNNode(geometry: mark)
        markerNode.position = point3d
        sphere.addChildNode(markerNode)
        markedVertices.append(markerNode)
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
    
    func extractTexture(from nodes:[SCNNode]) -> SCNMaterial {
//        let processedNodes = classifyCorners(from: nodes)
        
        let projectedPoints:[CGPoint] = nodes.map({
            let projPoint = activeSceneView.projectPoint($0.position as SCNVector3)
            let flattenedPoint = CGPoint(x: CGFloat(projPoint.x), y: CGFloat(projPoint.y))
//            print(flattenedPoint)
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
        return SCNMaterial()
    }
    
    func createPlane(with nodes:[SCNNode]) -> SCNNode {
        let positions:[SCNVector3] = nodes.map({$0.position as SCNVector3})
        let triangles:[[Int32]] = [[0, 1, 2], [2, 3, 0]]
        var elements:[SCNGeometryElement] = [SCNGeometryElement]()
        
        let vertexSource:SCNGeometrySource = SCNGeometrySource(vertices: positions, count: positions.count)
        
        for triangle in triangles {
            elements.append(SCNGeometryElement(indices: triangle, primitiveType: SCNGeometryPrimitiveType.triangles))
        }
        
        let planeShape = SCNGeometry(sources: [vertexSource], elements: elements)
        planeShape.materials.first?.diffuse.contents = markedPlanes.count == 1 ? UIColor.cyan : UIColor.purple
        planeShape.materials.first?.isDoubleSided = true
        
        //FIXME: we need the reverse perspective transformed version of the plane instead of directly using the trapezoidal plane if we want proper depth
        let planeNode = SCNNode(geometry: planeShape)
        return planeNode
        
    }
    
    func applyTexture(from texture:SCNMaterial, to node:SCNNode) {
//        TODO: also apply the texture we grabbed to the node that we cut out. although having some kind of scenekit or opengl function that directly grabbed plane and texture together would be even better
        extractedScene.rootNode.addChildNode(node)
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

protocol Lookable {}
protocol Walkable {}

extension UIView: Lookable {
    func enableLooking() {
        
    }
}

extension UIView: Walkable {
    func enableWalking() {
        
    }
}

extension GLKQuaternion {
    func toSCNQuaternion() -> SCNQuaternion {
        return SCNQuaternion(self.x, self.y, self.z, self.w)
    }
}

extension SCNQuaternion {
    func toGLKQuaternion() -> GLKQuaternion {
        return GLKQuaternion(q: (self.x, self.y, self.z, self.w))
    }
}

extension GLKQuaternion {
    func rotateBy(radiansOffsetX: Float, radiansOffsetY: Float) -> GLKQuaternion {
        // Perform up and down rotations around *CAMERA* X axis (note the order of multiplication)
        let xMultiplier = GLKQuaternionMakeWithAngleAndAxis(radiansOffsetY, 1, 0, 0)
        var rotatedQuaternion = GLKQuaternionMultiply(self, xMultiplier)
        
        // Perform side to side rotations around *WORLD* Y axis (note the order of multiplication, different from above)
        let yMultiplier = GLKQuaternionMakeWithAngleAndAxis(radiansOffsetX, 0, 1, 0)
        rotatedQuaternion = GLKQuaternionMultiply(yMultiplier, rotatedQuaternion)
        
        return rotatedQuaternion
    }
    
    func rotateBy(radiansOffsetZ: Float) -> GLKQuaternion {
        let zMultiplier = GLKQuaternionMakeWithAngleAndAxis(radiansOffsetZ, 0, 0, 1)
        let rotatedQuaternion = GLKQuaternionMultiply(self, zMultiplier)
        
        return rotatedQuaternion
    }
}

extension Float {
    func horizontalOffsetPixelsToRadians(view: UIView) -> (Float) {
        let xFov = GLKMathDegreesToRadians(60 * Float(view.bounds.size.width / view.bounds.size.height))
        return (xFov / Float(view.bounds.size.width)) * self
    }
    
    func verticalOffsetPixelsToRadians(view: UIView) -> (Float) {
        let yFov = GLKMathDegreesToRadians(60)
        return (yFov / Float(view.bounds.size.height)) * self
    }

}

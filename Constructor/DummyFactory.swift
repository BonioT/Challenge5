//
//  DummyFactory.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//

import SceneKit

struct DummyFactory {

    static func createDummy() -> SCNNode {

        let root = SCNNode()
        root.name = "Root"

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemGray
        material.lightingModel = .blinn

        // MARK: - Torso
        let torso = SCNNode(geometry: SCNBox(width: 1.2, height: 2, length: 0.6, chamferRadius: 0))
        torso.geometry?.materials = [material]
        torso.position = SCNVector3(0, 3, 0)
        torso.name = "Torso"
        root.addChildNode(torso)

        // MARK: - Head
        let head = SCNNode(geometry: SCNSphere(radius: 0.5))
        head.geometry?.materials = [material]
        head.position = SCNVector3(0, 1.6, 0)
        head.name = "Head"
        torso.addChildNode(head)

        // MARK: - Left Arm
        let leftUpperArm = jointNode(name: "LeftUpperArm", length: 1.2, material: material)
        leftUpperArm.position = SCNVector3(-1, 0.8, 0)
        torso.addChildNode(leftUpperArm)

        let leftLowerArm = jointNode(name: "LeftLowerArm", length: 1.1, material: material)
        leftLowerArm.position = SCNVector3(0, -1.1, 0)
        leftUpperArm.addChildNode(leftLowerArm)

        // MARK: - Right Arm
        let rightUpperArm = jointNode(name: "RightUpperArm", length: 1.2, material: material)
        rightUpperArm.position = SCNVector3(1, 0.8, 0)
        torso.addChildNode(rightUpperArm)

        let rightLowerArm = jointNode(name: "RightLowerArm", length: 1.1, material: material)
        rightLowerArm.position = SCNVector3(0, -1.1, 0)
        rightUpperArm.addChildNode(rightLowerArm)

        // MARK: - Left Leg
        let leftUpperLeg = jointNode(name: "LeftUpperLeg", length: 1.5, material: material)
        leftUpperLeg.position = SCNVector3(-0.5, -1, 0)
        torso.addChildNode(leftUpperLeg)

        let leftLowerLeg = jointNode(name: "LeftLowerLeg", length: 1.5, material: material)
        leftLowerLeg.position = SCNVector3(0, -1.5, 0)
        leftUpperLeg.addChildNode(leftLowerLeg)

        // MARK: - Right Leg
        let rightUpperLeg = jointNode(name: "RightUpperLeg", length: 1.5, material: material)
        rightUpperLeg.position = SCNVector3(0.5, -1, 0)
        torso.addChildNode(rightUpperLeg)

        let rightLowerLeg = jointNode(name: "RightLowerLeg", length: 1.5, material: material)
        rightLowerLeg.position = SCNVector3(0, -1.5, 0)
        rightUpperLeg.addChildNode(rightLowerLeg)

        return root
    }

    private static func jointNode(name: String, length: CGFloat, material: SCNMaterial) -> SCNNode {
        let node = SCNNode(geometry: SCNCylinder(radius: 0.25, height: length))
        node.geometry?.materials = [material]
        node.name = name
        node.pivot = SCNMatrix4MakeTranslation(0, Float(length / 2), 0)
        return node
    }
}

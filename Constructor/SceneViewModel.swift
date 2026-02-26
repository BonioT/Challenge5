//
//  SceneViewModel.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//

import Foundation
import SceneKit
import SwiftUI
import Combine

final class SceneViewModel: ObservableObject {
    @Published var scene: SCNScene = SCNScene()
    @Published var selectedNodeName: String? = nil

    var selectedNode: SCNNode? {
        didSet { selectedNodeName = selectedNode?.name }
    }

    init() {
        setupScene()
    }

    private func setupScene() {
        scene.background.contents = UIColor.systemGray6

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 6, 12)
        cameraNode.look(at: SCNVector3(0, 3, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)

        // Floor
        let floorNode = SCNNode(geometry: SCNFloor())
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
        scene.rootNode.addChildNode(floorNode)

        // Dummy
        let dummy = DummyFactory.createDummy()
        scene.rootNode.addChildNode(dummy)
    }

    // MARK: - Joint rotation (with clamp)
    func rotateSelectedJoint(deltaX: Float, deltaY: Float, deltaZ: Float) {
        guard let node = selectedNode else { return }

        let newX = clamp(node.eulerAngles.x + deltaX, min: -.pi/2, max: .pi/2)
        let newY = clamp(node.eulerAngles.y + deltaY, min: -.pi/2, max: .pi/2)
        let newZ = clamp(node.eulerAngles.z + deltaZ, min: -.pi/2, max: .pi/2)

        node.eulerAngles = SCNVector3(newX, newY, newZ)
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.max(min, Swift.min(max, value))
    }

    // MARK: - Poses
    enum PoseType: String, CaseIterable {
        case idle = "Idle"
        case walk = "Walk"
        case run = "Run"
        case jump = "Jump"
        case hero = "Hero"
        case attack = "Attack"
    }

    func applyPose(_ pose: PoseType) {
        guard let root = scene.rootNode.childNode(withName: "Root", recursively: true) else { return }
        resetPose(root)

        func n(_ name: String) -> SCNNode? { root.childNode(withName: name, recursively: true) }

        switch pose {
        case .idle:
            break

        case .walk:
            n("LeftUpperLeg")?.eulerAngles.x = 0.45
            n("RightUpperLeg")?.eulerAngles.x = -0.35
            n("LeftUpperArm")?.eulerAngles.x = -0.25
            n("RightUpperArm")?.eulerAngles.x = 0.25

        case .run:
            n("LeftUpperLeg")?.eulerAngles.x = 0.85
            n("RightUpperLeg")?.eulerAngles.x = -0.65
            n("LeftUpperArm")?.eulerAngles.x = -0.7
            n("RightUpperArm")?.eulerAngles.x = 0.7

        case .jump:
            n("LeftUpperLeg")?.eulerAngles.x = 0.9
            n("RightUpperLeg")?.eulerAngles.x = 0.9
            n("LeftLowerLeg")?.eulerAngles.x = -0.6
            n("RightLowerLeg")?.eulerAngles.x = -0.6

        case .hero:
            n("LeftUpperArm")?.eulerAngles.z = -0.9
            n("RightUpperArm")?.eulerAngles.z = 0.9
            n("Torso")?.eulerAngles.y = 0.2

        case .attack:
            n("RightUpperArm")?.eulerAngles.x = -1.0
            n("RightLowerArm")?.eulerAngles.x = -0.6
            n("Torso")?.eulerAngles.y = -0.15
        }
    }

    private func resetPose(_ root: SCNNode) {
        root.enumerateChildNodes { node, _ in
            node.eulerAngles = SCNVector3Zero
        }
    }
}

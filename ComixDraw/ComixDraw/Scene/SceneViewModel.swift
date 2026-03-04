//
//  SceneViewModel.swift
//  ComixDraw
//
//  Merged from Constructor (MVVM, poses) + ComixApp (multi-dummy, camera orbit, joint limits)
//

import Foundation
import SceneKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Debug info for node discovery
struct JointDebugInfo: Identifiable {
    let id = UUID()
    let jointName: String
    let found: Bool
    let matchedNode: String?
}

final class SceneViewModel: ObservableObject {

    // MARK: - Published State
    @Published var scene: SCNScene = SCNScene()
    @Published var dummies: [DummyState] = [DummyState(modelName: "seahorse")]
    @Published var selectedDummyID: UUID?
    @Published var selectedNodeName: String? = nil
    @Published var selectedBoneName: String? = nil  // Currently selected joint for drag

    // Camera orbit
    @Published var cameraDistance: Float = 12.0
    @Published var cameraAzimuth: Float = 0.0
    @Published var cameraElevation: Float = 25.0

    // Debug info
    @Published var discoveredNodeNames: [String] = []
    @Published var jointDebugInfo: [JointDebugInfo] = []

    // Light controls
    @Published var lightX: Float = 5.0
    @Published var lightY: Float = 10.0
    @Published var lightZ: Float = 5.0
    @Published var lightIntensity: Float = 1000.0
    @Published var showLight: Bool = true

    // Internal references
    private var dummyNodes: [UUID: SCNNode] = [:]
    private var boneMaps: [UUID: [String: SCNNode]] = [:]  // bone name → actual bone node
    var cameraNode: SCNNode?
    private var keyLightNode: SCNNode?
    private var lightIndicator: SCNNode?
    private var highlightedNode: SCNNode?           // Currently highlighted bone
    private var originalMaterials: [SCNMaterial]?    // Saved for unhighlight

    var selectedIndex: Int? {
        dummies.firstIndex(where: { $0.id == selectedDummyID })
    }

    // MARK: - Init

    init() {
        dummies[0].scale = 0.01
        setupScene()
        selectedDummyID = dummies.first?.id
    }

    // MARK: - Scene Setup

    private func setupScene() {
        scene.background.contents = UIColor.systemGray6

        // Camera
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.zFar = 100
        cam.camera?.zNear = 0.01
        cam.name = "Camera"
        scene.rootNode.addChildNode(cam)
        self.cameraNode = cam
        updateCamera()

        // Key Light (user-controllable)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = CGFloat(lightIntensity)
        keyLight.light?.castsShadow = true
        keyLight.position = SCNVector3(lightX, lightY, lightZ)
        keyLight.look(at: SCNVector3Zero)
        keyLight.name = "KeyLight"
        scene.rootNode.addChildNode(keyLight)
        self.keyLightNode = keyLight

        // Light position indicator (small yellow sphere)
        let indicator = SCNNode(geometry: SCNSphere(radius: 0.15))
        indicator.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
        indicator.geometry?.firstMaterial?.emission.contents = UIColor.systemYellow
        indicator.position = SCNVector3(lightX, lightY, lightZ)
        indicator.name = "LightIndicator"
        scene.rootNode.addChildNode(indicator)
        self.lightIndicator = indicator

        // Fill Light
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.intensity = 400
        fillLight.position = SCNVector3(-3, 5, -3)
        scene.rootNode.addChildNode(fillLight)

        // Ambient
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Floor
        let floorNode = SCNNode(geometry: SCNFloor())
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
        floorNode.name = "Floor"
        scene.rootNode.addChildNode(floorNode)

        // Load initial dummies
        for dummy in dummies {
            loadDummy(dummy)
        }
    }

    // MARK: - Light Controls

    func updateLight() {
        keyLightNode?.position = SCNVector3(lightX, lightY, lightZ)
        keyLightNode?.look(at: SCNVector3Zero)
        keyLightNode?.light?.intensity = CGFloat(lightIntensity)
        keyLightNode?.isHidden = !showLight

        lightIndicator?.position = SCNVector3(lightX, lightY, lightZ)
        lightIndicator?.isHidden = !showLight
    }

    // MARK: - Dummy Management

    func addDummy() {
        var newDummy = DummyState(modelName: "seahorse")
        newDummy.scale = 0.01
        newDummy.positionX = Float(dummies.count) * 2.0
        dummies.append(newDummy)
        selectedDummyID = newDummy.id
        loadDummy(newDummy)
    }

    func removeSelectedDummy() {
        guard let id = selectedDummyID else { return }
        dummyNodes[id]?.removeFromParentNode()
        dummyNodes.removeValue(forKey: id)
        dummies.removeAll { $0.id == id }
        selectedDummyID = dummies.first?.id
    }

    /// Import a 3D model from a file URL (user picks from Files)
    func importModel(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Cannot access file: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let scene = try SCNScene(url: url, options: [
                .checkConsistency: true,
                .convertToYUp: true
            ])

            let container = SCNNode()
            let modelName = url.deletingPathExtension().lastPathComponent
            container.name = modelName

            let children = scene.rootNode.childNodes
            for child in children {
                child.removeFromParentNode()
                container.addChildNode(child)
            }

            // Create a DummyState for the imported model
            var newDummy = DummyState(modelName: modelName)
            newDummy.scale = 0.01
            newDummy.positionX = Float(dummies.count) * 2.0
            dummies.append(newDummy)
            selectedDummyID = newDummy.id

            container.name = "Dummy_\(newDummy.id.uuidString)"
            container.position = SCNVector3(newDummy.positionX, newDummy.positionY, newDummy.positionZ)
            container.scale = SCNVector3(newDummy.scale, newDummy.scale, newDummy.scale)
            self.scene.rootNode.addChildNode(container)
            dummyNodes[newDummy.id] = container

            ModelLoader.printAllNodeNames(container)
            print("✅ Imported model '\(modelName)' from file")
        } catch {
            print("❌ Failed to import model: \(error.localizedDescription)")
        }
    }

    private func loadDummy(_ dummy: DummyState) {
        let node: SCNNode

        if let loaded = ModelLoader.loadModel(named: dummy.modelName) {
            node = loaded
            print("✅ Using imported model: \(dummy.modelName)")
        } else {
            node = DummyFactory.createDummy()
            print("⚠️ Fallback to code-generated mannequin")
        }

        node.name = "Dummy_\(dummy.id.uuidString)"
        node.position = SCNVector3(dummy.positionX, dummy.positionY, dummy.positionZ)
        node.scale = SCNVector3(dummy.scale, dummy.scale, dummy.scale)
        scene.rootNode.addChildNode(node)
        dummyNodes[dummy.id] = node

        // Build bone map from skinner for direct bone manipulation
        let boneMap = ModelLoader.buildBoneMap(from: node)
        boneMaps[dummy.id] = boneMap
        print("🗺️ Bone map for \(dummy.modelName): \(boneMap.count) entries")
        for (name, _) in boneMap.sorted(by: { $0.key < $1.key }) {
            print("   🔑 \(name)")
        }

        // Debug: verify joints
        verifyJoints(in: node)
    }

    private func verifyJoints(in node: SCNNode) {
        // Collect ALL node names for debug display
        var names: [String] = []
        node.enumerateChildNodes { child, _ in
            if let name = child.name, !name.isEmpty {
                let geo = child.geometry != nil ? " [GEO]" : ""
                let skin = child.skinner != nil ? " [SKIN]" : ""
                let bones = child.skinner != nil ? " (\(child.skinner!.bones.count) bones)" : ""
                names.append("\(name)\(geo)\(skin)\(bones)")
            }
        }
        // Also check skinner bones
        node.enumerateChildNodes { child, _ in
            if let skinner = child.skinner {
                for bone in skinner.bones {
                    if let boneName = bone.name, !names.contains(where: { $0.hasPrefix(boneName) }) {
                        names.append("\(boneName) [BONE]")
                    }
                }
            }
        }
        discoveredNodeNames = names

        // Check each joint
        let testJoints = JointRegistry.allConstraints
        var debugInfos: [JointDebugInfo] = []
        for constraint in testJoints {
            let jointName = constraint.name.components(separatedBy: "/").last ?? constraint.name
            if let found = ModelLoader.findJoint(named: constraint.name, in: node) {
                print("✅ Joint '\(jointName)' found → '\(found.name ?? "?")'")
                debugInfos.append(JointDebugInfo(jointName: jointName, found: true, matchedNode: found.name))
            } else {
                print("❌ Joint '\(jointName)' NOT found")
                debugInfos.append(JointDebugInfo(jointName: jointName, found: false, matchedNode: nil))
            }
        }
        jointDebugInfo = debugInfos
    }

    // MARK: - Update Transforms

    func updateDummyTransform(for dummy: DummyState) {
        guard let node = dummyNodes[dummy.id] else { return }
        node.scale = SCNVector3(dummy.scale, dummy.scale, dummy.scale)
        node.eulerAngles.y = dummy.rotationY * .pi / 180.0
        node.position = SCNVector3(dummy.positionX, dummy.positionY, dummy.positionZ)
    }

    func updateAllJoints(for dummy: DummyState) {
        guard let node = dummyNodes[dummy.id] else { return }

        let joints: [(String, SIMD3<Float>)] = [
            (JointRegistry.leftArm.name,      dummy.leftArmRotation),
            (JointRegistry.rightArm.name,     dummy.rightArmRotation),
            (JointRegistry.head.name,         dummy.headRotation),
            (JointRegistry.neck.name,         dummy.neckRotation),
            (JointRegistry.leftLeg.name,      dummy.leftLegRotation),
            (JointRegistry.rightLeg.name,     dummy.rightLegRotation),
            (JointRegistry.leftForearm.name,  dummy.leftForearmRotation),
            (JointRegistry.rightForearm.name, dummy.rightForearmRotation),
            (JointRegistry.leftKnee.name,     dummy.leftKneeRotation),
            (JointRegistry.rightKnee.name,    dummy.rightKneeRotation),
        ]

        for (jointPath, rotation) in joints {
            applyJointRotation(jointPath: jointPath, rotation: rotation, in: node, dummyID: dummy.id)
        }
    }

    private func applyJointRotation(jointPath: String, rotation: SIMD3<Float>, in root: SCNNode, dummyID: UUID) {
        let jointName = jointPath.components(separatedBy: "/").last ?? jointPath

        // PREFER bone map (exact skinner bone instances) over hierarchy search
        let jointNode: SCNNode?
        if let boneMap = boneMaps[dummyID], let bone = boneMap[jointName] {
            jointNode = bone
        } else {
            jointNode = ModelLoader.findJoint(named: jointPath, in: root)
        }

        guard let node = jointNode else { return }

        let rx = rotation.x * .pi / 180.0
        let ry = rotation.y * .pi / 180.0
        let rz = rotation.z * .pi / 180.0

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        node.eulerAngles = SCNVector3(rx, ry, rz)
        SCNTransaction.commit()
    }

    // MARK: - Interactive Joint Selection & Drag

    /// Map from bone node name to the DummyState property keypath
    private static let boneToKeyPath: [String: WritableKeyPath<DummyState, SIMD3<Float>>] = [
        "mixamorig_LeftArm":      \.leftArmRotation,
        "mixamorig_RightArm":     \.rightArmRotation,
        "mixamorig_Head":         \.headRotation,
        "mixamorig_Neck":         \.neckRotation,
        "mixamorig_LeftUpLeg":    \.leftLegRotation,
        "mixamorig_RightUpLeg":   \.rightLegRotation,
        "mixamorig_LeftForeArm":  \.leftForearmRotation,
        "mixamorig_RightForeArm": \.rightForearmRotation,
        "mixamorig_LeftLeg":      \.leftKneeRotation,
        "mixamorig_RightLeg":     \.rightKneeRotation,
    ]

    /// Map from bone name to its constraints
    private static let boneToConstraints: [String: JointConstraints] = {
        var map: [String: JointConstraints] = [:]
        for c in JointRegistry.allConstraints {
            let name = c.name.components(separatedBy: "/").last ?? c.name
            map[name] = c
        }
        return map
    }()

    /// Given a 3D hit point, find the nearest controllable bone
    func findNearestBone(worldHitPoint: SCNVector3, dummyID: UUID) -> SCNNode? {
        guard let boneMap = boneMaps[dummyID] else { return nil }

        var closest: SCNNode?
        var closestDist: Float = .infinity

        for (name, bone) in boneMap {
            guard Self.boneToKeyPath[name] != nil else { continue }

            // Use .presentation to get the actual rendered world position
            let bonePos = bone.presentation.worldPosition
            let dx = worldHitPoint.x - bonePos.x
            let dy = worldHitPoint.y - bonePos.y
            let dz = worldHitPoint.z - bonePos.z
            let dist = sqrt(dx*dx + dy*dy + dz*dz)

            if dist < closestDist {
                closestDist = dist
                closest = bone
            }
        }
        return closest
    }

    /// Select a bone: highlight it and set as active
    func selectBone(_ bone: SCNNode) {
        deselectBone()  // clear previous

        selectedBoneName = bone.name
        highlightedNode = bone

        // Highlight: yellow emission glow
        if let geometry = bone.geometry {
            for material in geometry.materials {
                material.emission.contents = UIColor.systemYellow.withAlphaComponent(0.6)
            }
        }

        // Pulse animation on the dummy root for visual feedback
        if let dummyID = selectedDummyID, let dummyNode = dummyNodes[dummyID] {
            let pulseUp = SCNAction.scale(by: 1.08, duration: 0.12)
            pulseUp.timingMode = .easeOut
            let pulseDown = SCNAction.scale(by: 1.0 / 1.08, duration: 0.15)
            pulseDown.timingMode = .easeIn
            dummyNode.runAction(.sequence([pulseUp, pulseDown]))
        }

        print("🎯 Selected bone: \(bone.name ?? "?")")
    }

    /// Deselect: remove highlight
    func deselectBone() {
        if let node = highlightedNode {
            func removeHighlight(from node: SCNNode) {
                if let geometry = node.geometry {
                    for material in geometry.materials {
                        material.emission.contents = UIColor.black
                    }
                }
            }
            removeHighlight(from: node)
        }

        selectedBoneName = nil
        highlightedNode = nil
    }

    /// Rotate the selected joint based on screen-space drag delta
    func dragRotateJoint(dx: Float, dy: Float) {
        guard let boneName = selectedBoneName,
              let dummyID = selectedDummyID,
              let index = selectedIndex,
              let keyPath = Self.boneToKeyPath[boneName] else { return }

        let sensitivity: Float = 0.5

        // Get current rotation in degrees
        var rotation = dummies[index][keyPath: keyPath]

        // Horizontal drag → Y rotation, Vertical drag → X rotation
        rotation.y += dx * sensitivity
        rotation.x -= dy * sensitivity

        // Clamp to constraints
        if let constraints = Self.boneToConstraints[boneName] {
            if let xr = constraints.xRange {
                rotation.x = max(xr.minDegrees, min(xr.maxDegrees, rotation.x))
            }
            if let yr = constraints.yRange {
                rotation.y = max(yr.minDegrees, min(yr.maxDegrees, rotation.y))
            }
            if let zr = constraints.zRange {
                rotation.z = max(zr.minDegrees, min(zr.maxDegrees, rotation.z))
            }
        }

        // Write back to DummyState (syncs sliders)
        dummies[index][keyPath: keyPath] = rotation

        // Apply immediately to the bone
        if let boneMap = boneMaps[dummyID], let boneNode = boneMap[boneName] {
            let rx = rotation.x * .pi / 180.0
            let ry = rotation.y * .pi / 180.0
            let rz = rotation.z * .pi / 180.0
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0
            boneNode.eulerAngles = SCNVector3(rx, ry, rz)
            SCNTransaction.commit()
        }
    }

    // MARK: - Camera Orbit

    /// Camera lookAt target (movable via 2-finger pan)
    var lookAtTarget = SCNVector3(0, 1.0, 0)

    func updateCamera() {
        guard let cam = cameraNode else { return }
        let az = cameraAzimuth * .pi / 180.0
        let el = cameraElevation * .pi / 180.0
        let x = cameraDistance * cos(el) * sin(az)
        let y = cameraDistance * sin(el)
        let z = cameraDistance * cos(el) * cos(az)
        cam.position = SCNVector3(
            lookAtTarget.x + x,
            lookAtTarget.y + y,
            lookAtTarget.z + z
        )
        cam.look(at: lookAtTarget)
        objectWillChange.send()
    }

    func updateCameraWithTarget(lookAtX: Float, lookAtY: Float, lookAtZ: Float) {
        lookAtTarget = SCNVector3(lookAtX, lookAtY, lookAtZ)
        updateCamera()
    }

    // MARK: - Pose Presets

    enum PoseType: String, CaseIterable {
        case idle = "Idle"
        case walk = "Walk"
        case run = "Run"
        case jump = "Jump"
        case hero = "Hero"
        case attack = "Attack"
    }

    func applyPose(_ pose: PoseType) {
        guard let index = selectedIndex else { return }
        resetDummy(index: index)

        switch pose {
        case .idle:
            break
        case .walk:
            dummies[index].leftLegRotation = SIMD3(210, 180, 0)
            dummies[index].rightLegRotation = SIMD3(150, 180, 0)
            dummies[index].leftArmRotation = SIMD3(-25, 0, 0)
            dummies[index].rightArmRotation = SIMD3(25, 0, 0)
        case .run:
            dummies[index].leftLegRotation = SIMD3(225, 180, 0)
            dummies[index].rightLegRotation = SIMD3(130, 180, 0)
            dummies[index].leftArmRotation = SIMD3(-70, 0, 0)
            dummies[index].rightArmRotation = SIMD3(70, 0, 0)
            dummies[index].leftForearmRotation = SIMD3(45, 0, 0)
            dummies[index].rightForearmRotation = SIMD3(45, 0, 0)
        case .jump:
            dummies[index].leftLegRotation = SIMD3(210, 180, 0)
            dummies[index].rightLegRotation = SIMD3(210, 180, 0)
            dummies[index].leftKneeRotation = SIMD3(-60, 0, 0)
            dummies[index].rightKneeRotation = SIMD3(-60, 0, 0)
            dummies[index].leftArmRotation = SIMD3(0, -90, 90)
            dummies[index].rightArmRotation = SIMD3(0, 90, 90)
        case .hero:
            dummies[index].leftArmRotation = SIMD3(0, -90, 90)
            dummies[index].rightArmRotation = SIMD3(0, 90, 90)
            dummies[index].headRotation = SIMD3(10, 0, 0)
        case .attack:
            dummies[index].rightArmRotation = SIMD3(-60, 0, 80)
            dummies[index].rightForearmRotation = SIMD3(90, 0, 0)
            dummies[index].leftArmRotation = SIMD3(20, 0, 30)
        }

        updateAllJoints(for: dummies[index])
    }

    // MARK: - Reset

    func resetDummy(index: Int) {
        guard dummies.indices.contains(index) else { return }
        dummies[index].scale = 0.01
        dummies[index].rotationY = 0.0
        dummies[index].positionX = Float(index) * 2.0
        dummies[index].positionY = 0.0
        dummies[index].positionZ = 0.0
        dummies[index].leftArmRotation = .zero
        dummies[index].rightArmRotation = .zero
        dummies[index].headRotation = .zero
        dummies[index].neckRotation = .zero
        dummies[index].leftLegRotation = SIMD3<Float>(180, 180, 0)
        dummies[index].rightLegRotation = SIMD3<Float>(180, 180, 0)
        dummies[index].leftForearmRotation = .zero
        dummies[index].rightForearmRotation = .zero
        dummies[index].leftKneeRotation = .zero
        dummies[index].rightKneeRotation = .zero

        updateDummyTransform(for: dummies[index])
        updateAllJoints(for: dummies[index])
    }
}

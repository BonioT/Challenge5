//
//  SceneRoomViewCustomizable.swift
//  Comiixx
//
//  Created by Antigravity on 25/02/26.
//

import SwiftUI
import RealityKit
import Combine

struct SceneRoomViewCustomizable: UIViewRepresentable {
    @Binding var dummies: [DummyState]
    @Binding var cameraDistance: Float
    @Binding var cameraAzimuth: Float
    @Binding var cameraElevation: Float

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        context.coordinator.setupScene(in: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        let coordinator = context.coordinator

        for dummy in dummies where coordinator.loadedModels[dummy.id] == nil {
            Task { await coordinator.loadModel(for: dummy, in: uiView) }
        }

        let currentIDs = Set(dummies.map { $0.id })
        for id in coordinator.loadedModels.keys where !currentIDs.contains(id) {
            coordinator.removeModel(for: id)
        }

        for dummy in dummies {
            coordinator.updateModelTransform(for: dummy)
            coordinator.updateAllJoints(for: dummy)
        }

        coordinator.updateCameraTransform(distance: cameraDistance, azimuth: cameraAzimuth, elevation: cameraElevation)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    class Coordinator {
        var loadedModels: [UUID: ModelEntity] = [:]
        var floorOffsets: [UUID: Float] = [:]   // 👈 store per-dummy floor offset
        var worldAnchor: AnchorEntity?
        var floorEntity: ModelEntity?
        var cameraEntity: PerspectiveCamera?

        func setupScene(in arView: ARView) {
            let worldAnchor = AnchorEntity(world: .zero)
            arView.scene.addAnchor(worldAnchor)
            self.worldAnchor = worldAnchor
            setupFloor(on: worldAnchor)
            setupLights(on: worldAnchor)
            let camera = PerspectiveCamera()
            camera.position = [0, 1.5, 4]
            camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
            worldAnchor.addChild(camera)
            self.cameraEntity = camera
        }

        func loadModel(for dummy: DummyState, in arView: ARView) async {
            guard let anchor = worldAnchor else { return }
            guard let model = await ModelManager.shared.spawnModel(named: dummy.modelName, in: arView, at: anchor) else { return }

            let bounds = model.visualBounds(relativeTo: model)
            let offset = bounds.extents.y / 2.0
            floorOffsets[dummy.id] = offset
            model.position.y = offset + dummy.positionY
            loadedModels[dummy.id] = model
        }

        func removeModel(for id: UUID) {
            loadedModels[id]?.removeFromParent()
            loadedModels.removeValue(forKey: id)
            floorOffsets.removeValue(forKey: id)
        }

        func updateModelTransform(for dummy: DummyState) {
            guard let model = loadedModels[dummy.id] else { return }
            let offset = floorOffsets[dummy.id] ?? 0
            model.scale = SIMD3<Float>(repeating: dummy.scale)
            model.orientation = simd_quatf(angle: dummy.rotationY * .pi / 180.0, axis: [0, 1, 0])
            model.position = [dummy.positionX, dummy.positionY + offset, dummy.positionZ]
        }

        func updateAllJoints(for dummy: DummyState) {
            guard let model = loadedModels[dummy.id] else { return }
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
            for (name, rotation) in joints {
                applyRotation(jointName: name, rotation: rotation, to: model)
            }
        }

        func updateCameraTransform(distance: Float, azimuth: Float, elevation: Float) {
            guard let camera = cameraEntity else { return }
            let az = azimuth * .pi / 180.0
            let el = elevation * .pi / 180.0
            camera.position = [
                distance * cos(el) * sin(az),
                distance * sin(el),
                distance * cos(el) * cos(az)
            ]
            camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
        }

        private func applyRotation(jointName: String, rotation: SIMD3<Float>, to entity: Entity) {
            if let modelEntity = entity as? ModelEntity,
               let index = modelEntity.jointNames.firstIndex(where: { $0.hasSuffix(jointName) }) {
                let qx = simd_quatf(angle: rotation.x * .pi / 180.0, axis: [1, 0, 0])
                let qy = simd_quatf(angle: rotation.y * .pi / 180.0, axis: [0, 1, 0])
                let qz = simd_quatf(angle: rotation.z * .pi / 180.0, axis: [0, 0, 1])
                modelEntity.jointTransforms[index].rotation = qx * qy * qz
                return
            }
            for child in entity.children {
                applyRotation(jointName: jointName, rotation: rotation, to: child)
            }
        }

        private func setupFloor(on anchor: AnchorEntity) {
            let mesh = MeshResource.generatePlane(width: 5, depth: 5)
            let material = SimpleMaterial(color: .white.withAlphaComponent(0.5), isMetallic: false)
            let floor = ModelEntity(mesh: mesh, materials: [material])
            floor.name = "Floor"
            floor.generateCollisionShapes(recursive: true)
            self.floorEntity = floor
            anchor.addChild(floor)
        }

        private func setupLights(on anchor: AnchorEntity) {
            let main = DirectionalLight()
            main.light.intensity = 5000
            main.position = [2, 5, 2]
            main.look(at: [0, 0, 0], from: main.position, relativeTo: nil)
            anchor.addChild(main)

            let ambient = Entity()
            ambient.components.set(DirectionalLightComponent(color: .white, intensity: 2000))
            ambient.position = [-2, 3, -2]
            anchor.addChild(ambient)
        }
    }
}
import RealityKit
import SwiftUI

struct SceneRoomViewCustomizable: UIViewRepresentable {
    @ObservedObject var editorState: SceneEditorViewModel

    @Binding var triggerSnapshot: Bool
    @Binding var snapshotImage: UIImage?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        context.coordinator.setupScene(in: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        let coordinator = context.coordinator
        coordinator.editorState = editorState

        let stateIDs = Set(editorState.dummies.map { $0.id })
        for (id, _) in coordinator.loadedModels where !stateIDs.contains(id) {
            coordinator.removeModel(id: id)
        }

        for dummy in editorState.dummies {
            if coordinator.loadedModels[dummy.id] == nil
                && !coordinator.spawningModels.contains(dummy.id)
            {
                coordinator.spawningModels.insert(dummy.id)
                Task { await coordinator.loadModel(for: dummy, in: uiView) }
            } else if coordinator.loadedModels[dummy.id] != nil && !coordinator.isGesturing {
                coordinator.updateModelTransform(for: dummy)
                coordinator.updateAllJoints(for: dummy)
            }
        }

        coordinator.updateCamera()
        coordinator.updateLightPosition()

        if triggerSnapshot {
            DispatchQueue.main.async {
                uiView.snapshot(saveToHDR: false) { image in
                    self.snapshotImage = image
                    self.triggerSnapshot = false
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(editorState: editorState) }

    @MainActor
    class Coordinator: NSObject {
        var editorState: SceneEditorViewModel
        var loadedModels: [UUID: ModelEntity] = [:]
        var spawningModels: Set<UUID> = []
        var floorOffset: Float = 0
        var isGesturing = false
        var worldAnchor: AnchorEntity?
        var floorEntity: ModelEntity?
        var cameraEntity: PerspectiveCamera?
        var mainLightEntity: DirectionalLight?
        var lightIndicatorEntity: ModelEntity?
        var pinchStartDistance: Float = 0
        var panStartAzimuth: Float = 0
        var panStartElevation: Float = 0

        init(editorState: SceneEditorViewModel) {
            self.editorState = editorState
            super.init()
        }

        func setupScene(in arView: ARView) {
            let anchor = AnchorEntity(world: .zero)
            arView.scene.addAnchor(anchor)
            self.worldAnchor = anchor

            setupFloor(on: anchor)
            setupLights(on: anchor)

            let camera = PerspectiveCamera()
            camera.position = [0, 1.5, 4]
            camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
            anchor.addChild(camera)
            self.cameraEntity = camera

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            arView.addGestureRecognizer(pinch)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            arView.addGestureRecognizer(pan)
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            switch recognizer.state {
            case .began:
                pinchStartDistance = editorState.cameraDistance
            case .changed:
                let scale = Float(recognizer.scale)
                let newDistance = pinchStartDistance / scale
                editorState.cameraDistance = min(20.0, max(1.0, newDistance))
            default: break
            }
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard recognizer.numberOfTouches == 2 || recognizer.state == .ended else { return }
            switch recognizer.state {
            case .began:
                panStartAzimuth = editorState.cameraAzimuth
                panStartElevation = editorState.cameraElevation
            case .changed:
                let translation = recognizer.translation(in: recognizer.view)
                let deltaAzimuth = Float(translation.x) * 0.3
                let deltaElevation = Float(-translation.y) * 0.2
                var newAzimuth = panStartAzimuth + deltaAzimuth
                if newAzimuth < 0 { newAzimuth += 360 }
                if newAzimuth > 360 { newAzimuth -= 360 }
                editorState.cameraAzimuth = newAzimuth
                editorState.cameraElevation = min(80, max(-30, panStartElevation + deltaElevation))
            default: break
            }
        }

        func loadModel(for dummy: DummyState, in arView: ARView) async {
            guard let anchor = worldAnchor else {
                spawningModels.remove(dummy.id)
                return
            }
            guard let model = await ModelManager.shared.spawnModel(
                named: dummy.modelName, in: arView, at: anchor)
            else {
                spawningModels.remove(dummy.id)
                return
            }

            model.name = dummy.id.uuidString

            let bounds = model.visualBounds(relativeTo: model)
            floorOffset = bounds.extents.y / 2.0
            model.position.y = floorOffset + dummy.positionY
            loadedModels[dummy.id] = model
            spawningModels.remove(dummy.id)

            updateModelTransform(for: dummy)
            updateAllJoints(for: dummy)

            let gestures = arView.installGestures([.translation, .rotation, .scale], for: model)
            for gesture in gestures {
                gesture.addTarget(self, action: #selector(handleGesture(_:)))
            }
        }

        func removeModel(id: UUID) {
            loadedModels[id]?.removeFromParent()
            loadedModels.removeValue(forKey: id)
        }

        @objc func handleGesture(_ recognizer: UIGestureRecognizer) {
            var recognizedEntity: Entity?
            if let t = recognizer as? EntityTranslationGestureRecognizer {
                recognizedEntity = t.entity
            } else if let r = recognizer as? EntityRotationGestureRecognizer {
                recognizedEntity = r.entity
            } else if let s = recognizer as? EntityScaleGestureRecognizer {
                recognizedEntity = s.entity
            }

            guard let entity = recognizedEntity as? ModelEntity,
                let uuid = UUID(uuidString: entity.name),
                let dummyIndex = editorState.dummies.firstIndex(where: { $0.id == uuid })
            else { return }

            isGesturing = (recognizer.state == .began || recognizer.state == .changed)

            if recognizer.state == .began {
                editorState.selectedDummyID = uuid
            }

            if isGesturing {
                let pos = SIMD3<Float>(
                    max(-200, min(200, entity.position.x)),
                    max(-200, min(200, entity.position.y)),
                    max(-200, min(200, entity.position.z))
                )
                entity.position = pos

                let s = max(0.1, min(5.0, entity.scale.x))
                entity.scale = SIMD3<Float>(repeating: s)

                editorState.dummies[dummyIndex].positionX = pos.x
                editorState.dummies[dummyIndex].positionY = pos.y - floorOffset
                editorState.dummies[dummyIndex].positionZ = pos.z
                editorState.dummies[dummyIndex].scale = s

                let q = entity.orientation
                let angle = atan2(2.0 * (q.real * q.imag.y + q.imag.x * q.imag.z),
                                  1.0 - 2.0 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z))
                var degreesY = angle * 180.0 / .pi
                if degreesY < 0 { degreesY += 360.0 }
                editorState.dummies[dummyIndex].rotationY = degreesY
            }
        }

        func updateModelTransform(for dummy: DummyState) {
            guard let model = loadedModels[dummy.id] else { return }
            model.scale = SIMD3<Float>(repeating: dummy.scale)

            let qx = simd_quatf(angle: dummy.rotationX * .pi / 180.0, axis: [1, 0, 0])
            let qy = simd_quatf(angle: dummy.rotationY * .pi / 180.0, axis: [0, 1, 0])
            let qz = simd_quatf(angle: dummy.rotationZ * .pi / 180.0, axis: [0, 0, 1])
            model.orientation = qx * qy * qz

            model.position = [dummy.positionX, dummy.positionY + floorOffset, dummy.positionZ]
        }

        func updateAllJoints(for dummy: DummyState) {
            guard let model = loadedModels[dummy.id] else { return }

            applyRotation(jointName: JointRegistry.leftArm.name, rotation: dummy.leftArmRotation, to: model)
            applyRotation(jointName: JointRegistry.rightArm.name, rotation: dummy.rightArmRotation, to: model)
            applyRotation(jointName: JointRegistry.head.name, rotation: dummy.headRotation, to: model)
            applyRotation(jointName: JointRegistry.neck.name, rotation: dummy.neckRotation, to: model)
            applyRotation(jointName: JointRegistry.torso.name, rotation: dummy.torsoRotation, to: model)
            applyRotation(jointName: JointRegistry.leftLeg.name, rotation: dummy.leftLegRotation, to: model)
            applyRotation(jointName: JointRegistry.rightLeg.name, rotation: dummy.rightLegRotation, to: model)
            applyRotation(jointName: JointRegistry.leftForearm.name, rotation: dummy.leftForearmRotation, to: model)
            applyRotation(jointName: JointRegistry.rightForearm.name, rotation: dummy.rightForearmRotation, to: model)
            applyRotation(jointName: JointRegistry.leftKnee.name, rotation: dummy.leftKneeRotation, to: model)
            applyRotation(jointName: JointRegistry.rightKnee.name, rotation: dummy.rightKneeRotation, to: model)
        }

        func updateCamera() {
            guard let camera = cameraEntity else { return }
            let az = editorState.cameraAzimuth * .pi / 180.0
            let el = editorState.cameraElevation * .pi / 180.0
            let d = editorState.cameraDistance
            let target = SIMD3<Float>(editorState.cameraTargetX, editorState.cameraTargetY, editorState.cameraTargetZ)

            camera.position = [
                target.x + d * cos(el) * sin(az),
                target.y + d * sin(el),
                target.z + d * cos(el) * cos(az),
            ]
            camera.look(at: target, from: camera.position, relativeTo: nil)
        }

        func updateLightPosition() {
            guard let light = mainLightEntity else { return }
            light.position = editorState.lightPosition
            light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
            lightIndicatorEntity?.position = editorState.lightPosition
        }

        private func applyRotation(jointName: String, rotation: SIMD3<Float>, to entity: Entity) {
            if let modelEntity = entity as? ModelEntity,
                let index = modelEntity.jointNames.firstIndex(where: { $0.hasSuffix(jointName) })
            {
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
            main.light.color = .white
            main.light.intensity = 5000
            main.position = editorState.lightPosition
            main.look(at: [0, 0, 0], from: main.position, relativeTo: nil)
            anchor.addChild(main)
            self.mainLightEntity = main

            let indicatorMesh = MeshResource.generateSphere(radius: 0.06)
            let indicatorMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
            let indicator = ModelEntity(mesh: indicatorMesh, materials: [indicatorMaterial])
            indicator.position = editorState.lightPosition
            anchor.addChild(indicator)
            self.lightIndicatorEntity = indicator

            let ambient = Entity()
            ambient.components.set(DirectionalLightComponent(color: .white, intensity: 2000))
            ambient.position = [-2, 3, -2]
            anchor.addChild(ambient)
        }
    }
}

//
//  SceneViewContainer.swift
//  ComixDraw
//
//  UIViewRepresentable wrapping SCNView with gesture-based camera and joint manipulation
//

import SwiftUI
import SceneKit

struct SceneViewContainer: UIViewRepresentable {

    @ObservedObject var viewModel: SceneViewModel
    var onViewReady: ((SCNView) -> Void)? = nil

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = viewModel.scene
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X

        if let cam = viewModel.scene.rootNode.childNode(withName: "Camera", recursively: true) {
            view.pointOfView = cam
        }

        // --- Gestures ---

        // 1-finger drag → orbit OR rotate selected joint
        let oneFingerPan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleOneFingerDrag(_:))
        )
        oneFingerPan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(oneFingerPan)

        // Pinch → zoom
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinch)

        // 2-finger drag → pan camera target
        let twoFingerPan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(twoFingerPan)

        // Tap → select joint or deselect
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tap)

        context.coordinator.scnView = view

        DispatchQueue.main.async {
            onViewReady?(view)
        }

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let cam = viewModel.scene.rootNode.childNode(withName: "Camera", recursively: true) {
            uiView.pointOfView = cam
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject {
        var viewModel: SceneViewModel
        weak var scnView: SCNView?

        var lookAtX: Float = 0
        var lookAtY: Float = 1.0
        var lookAtZ: Float = 0

        init(viewModel: SceneViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - Tap → Select joint / deselect

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])

            // Check if we hit a part of a dummy
            if let hit = hits.first {
                let hitNode = hit.node

                // Find which dummy was tapped
                var dummyID: UUID?
                var current: SCNNode? = hitNode
                while let node = current {
                    if let name = node.name, name.hasPrefix("Dummy_") {
                        let uuidStr = String(name.dropFirst("Dummy_".count))
                        dummyID = UUID(uuidString: uuidStr)
                        break
                    }
                    current = node.parent
                }

                if let dummyID = dummyID {
                    viewModel.selectedDummyID = dummyID

                    // Find nearest controllable bone using 3D hit point
                    if let bone = viewModel.findNearestBone(
                        worldHitPoint: hit.worldCoordinates, dummyID: dummyID
                    ) {
                        viewModel.selectBone(bone)
                    } else {
                        viewModel.deselectBone()
                    }
                } else {
                    // Tapped floor or empty → deselect
                    viewModel.deselectBone()
                }
            } else {
                // Tapped empty space → deselect
                viewModel.deselectBone()
            }
        }

        // MARK: - 1 finger drag → orbit OR rotate joint

        @objc func handleOneFingerDrag(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }

            if gesture.state == .changed {
                let translation = gesture.translation(in: view)
                let dx = Float(translation.x)
                let dy = Float(translation.y)

                if viewModel.selectedBoneName != nil {
                    // Joint is selected → rotate it
                    viewModel.dragRotateJoint(dx: dx, dy: dy)
                } else {
                    // No joint selected → orbit camera
                    viewModel.cameraAzimuth += dx * 0.4
                    viewModel.cameraElevation -= dy * 0.3
                    viewModel.cameraElevation = max(-30, min(80, viewModel.cameraElevation))
                    viewModel.updateCamera()
                }

                gesture.setTranslation(.zero, in: view)
            }
        }

        // MARK: - Pinch → zoom

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                let factor = Float(1.0 / gesture.scale)
                viewModel.cameraDistance *= factor
                viewModel.cameraDistance = max(1, min(30, viewModel.cameraDistance))
                viewModel.updateCamera()
                gesture.scale = 1.0
            }
        }

        // MARK: - 2 finger drag → pan

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view, let cam = viewModel.cameraNode else { return }
            if gesture.state == .changed {
                let translation = gesture.translation(in: view)
                let right = cam.simdWorldRight
                let up = cam.simdWorldUp
                let panSpeed: Float = 0.005 * viewModel.cameraDistance
                let dx = -Float(translation.x) * panSpeed
                let dy = Float(translation.y) * panSpeed

                lookAtX += right.x * dx + up.x * dy
                lookAtY += right.y * dx + up.y * dy
                lookAtZ += right.z * dx + up.z * dy

                viewModel.updateCameraWithTarget(
                    lookAtX: lookAtX, lookAtY: lookAtY, lookAtZ: lookAtZ
                )
                gesture.setTranslation(.zero, in: view)
            }
        }
    }
}

//
//  SceneViewContainer.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//

import SwiftUI
import SceneKit

struct SceneViewContainer: UIViewRepresentable {

    @ObservedObject var viewModel: SceneViewModel
    var onViewReady: ((SCNView) -> Void)? = nil

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = viewModel.scene
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .clear

        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        DispatchQueue.main.async {
            onViewReady?(view)
        }

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject {
        var viewModel: SceneViewModel

        init(viewModel: SceneViewModel) {
            self.viewModel = viewModel
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: nil)
            viewModel.selectedNode = hits.first?.node
        }
    }
}

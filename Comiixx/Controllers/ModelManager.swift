//
//  ModelManager.swift
//  Comiixx
//
//  Created by Antigravity on 25/02/26.
//

import RealityKit
import SwiftUI
import Combine

@MainActor
class ModelManager {
    static let shared = ModelManager()

    // Loading logic using Async/Await
    func spawnModel(named name: String, in arView: ARView, at anchor: AnchorEntity) async -> ModelEntity? {
    do {
        let rootEntity = try await Entity.load(named: name)
        
        // Find the first ModelEntity with joints in the hierarchy
        guard let model = findSkeletalModel(in: rootEntity) else {
            print("⚠️ No skeletal ModelEntity found")
            return nil
        }
        
        configureInteractions(for: model)
        anchor.addChild(rootEntity) // Add root, not just model
        arView.installGestures([.translation, .rotation, .scale], for: model)
        
        print("✅ Model \(name) ready, joints: \(model.jointNames.count)")
        return model
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        return nil
    }
}

private func findSkeletalModel(in entity: Entity) -> ModelEntity? {
    if let modelEntity = entity as? ModelEntity, !modelEntity.jointNames.isEmpty {
        return modelEntity
    }
    for child in entity.children {
        if let found = findSkeletalModel(in: child) {
            return found
        }
    }
    return nil
}
    private func configureInteractions(for model: ModelEntity) {
        // Generate collision shapes for interaction
        model.generateCollisionShapes(recursive: true)

        // Enable input (required for gestures)
        model.components.set(InputTargetComponent())
    }
}

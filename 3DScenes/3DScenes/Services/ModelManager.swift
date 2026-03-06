import RealityKit

@MainActor
class ModelManager {
    static let shared = ModelManager()

    func spawnModel(named name: String, in arView: ARView, at anchor: AnchorEntity) async -> ModelEntity? {
        do {
            let rootEntity = try await Entity(named: name)

            guard let model = findSkeletalModel(in: rootEntity) else {
                return nil
            }

            model.generateCollisionShapes(recursive: true)
            model.components.set(InputTargetComponent())
            anchor.addChild(rootEntity)
            return model
        } catch {
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
}

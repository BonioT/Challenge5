import Combine
import Foundation

class SceneEditorViewModel: ObservableObject {
    var sceneId: UUID
    var sceneName: String
    @Published var dummies: [DummyState]
    @Published var selectedDummyID: UUID?
    @Published var sheets: [DrawingSheet]

    @Published var cameraDistance: Float = 4.27
    @Published var cameraAzimuth: Float = 0.0
    @Published var cameraElevation: Float = 20.6

    @Published var cameraTargetX: Float = 0.0
    @Published var cameraTargetY: Float = 0.0
    @Published var cameraTargetZ: Float = 0.0

    @Published var lightPosition: SIMD3<Float> = SIMD3<Float>(2, 5, 2)

    init(modelName: String = "dummyM") {
        self.sceneId = UUID()
        self.sceneName = "New Scene"
        let defaultDummy = DummyState(modelName: modelName)
        self.dummies = [defaultDummy]
        self.selectedDummyID = defaultDummy.id
        self.sheets = []
    }

    init(document: SceneDocument) {
        self.sceneId = document.id
        self.sceneName = document.name
        self.cameraDistance = document.cameraDistance
        self.cameraAzimuth = document.cameraAzimuth
        self.cameraElevation = document.cameraElevation
        self.cameraTargetX = document.cameraTargetX
        self.cameraTargetY = document.cameraTargetY
        self.cameraTargetZ = document.cameraTargetZ
        self.lightPosition = document.lightPosition
        self.dummies = document.dummies
        self.selectedDummyID = document.dummies.first?.id
        self.sheets = document.sheets
    }

    func buildDocument() -> SceneDocument {
        SceneDocument(
            id: sceneId,
            name: sceneName,
            createdAt: Date(),
            lastModified: Date(),
            cameraDistance: cameraDistance,
            cameraAzimuth: cameraAzimuth,
            cameraElevation: cameraElevation,
            cameraTargetX: cameraTargetX,
            cameraTargetY: cameraTargetY,
            cameraTargetZ: cameraTargetZ,
            lightPosition: lightPosition,
            dummies: dummies,
            sheets: sheets
        )
    }

    func resetDummy() {
        guard let id = selectedDummyID, let index = dummies.firstIndex(where: { $0.id == id })
        else { return }

        dummies[index].scale = 1.0
        dummies[index].rotationX = 0.0
        dummies[index].rotationY = 0.0
        dummies[index].rotationZ = 0.0
        dummies[index].positionX = 0.0
        dummies[index].positionY = -90.0
        dummies[index].positionZ = 0.0
        dummies[index].leftArmRotation = .zero
        dummies[index].rightArmRotation = .zero
        dummies[index].headRotation = .zero
        dummies[index].neckRotation = .zero
        dummies[index].torsoRotation = .zero
        dummies[index].leftLegRotation = SIMD3<Float>(180, 180, 0)
        dummies[index].rightLegRotation = SIMD3<Float>(180, 180, 0)
        dummies[index].leftForearmRotation = .zero
        dummies[index].rightForearmRotation = .zero
        dummies[index].leftKneeRotation = .zero
        dummies[index].rightKneeRotation = .zero
    }
}

import Foundation
import simd

struct DrawingSheet: Identifiable, Codable {
    var id: UUID
    var createdAt: Date
}

struct SceneDocument: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastModified: Date

    var cameraDistance: Float
    var cameraAzimuth: Float
    var cameraElevation: Float

    var cameraTargetX: Float
    var cameraTargetY: Float
    var cameraTargetZ: Float

    var lightPosition: SIMD3<Float>

    var dummies: [DummyState]
    var sheets: [DrawingSheet]

    init(
        id: UUID = UUID(),
        name: String = "New Scene",
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        cameraDistance: Float = 4.27,
        cameraAzimuth: Float = 0.0,
        cameraElevation: Float = 20.6,
        cameraTargetX: Float = 0.0,
        cameraTargetY: Float = 0.0,
        cameraTargetZ: Float = 0.0,
        lightPosition: SIMD3<Float> = SIMD3<Float>(2, 5, 2),
        dummies: [DummyState] = [],
        sheets: [DrawingSheet] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.cameraDistance = cameraDistance
        self.cameraAzimuth = cameraAzimuth
        self.cameraElevation = cameraElevation
        self.cameraTargetX = cameraTargetX
        self.cameraTargetY = cameraTargetY
        self.cameraTargetZ = cameraTargetZ
        self.lightPosition = lightPosition
        self.dummies = dummies
        self.sheets = sheets
    }
}

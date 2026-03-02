// DummyModel.swift
import RealityKit
import simd

struct DummyState: Identifiable {
    let id: UUID
    var modelName: String
    var scale: Float = 1.0
    var rotationY: Float = 0.0
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var leftArmRotation: SIMD3<Float> = .zero
    var rightArmRotation: SIMD3<Float> = .zero
    var headRotation: SIMD3<Float> = .zero
    var neckRotation: SIMD3<Float> = .zero
    var leftLegRotation: SIMD3<Float> = .zero
    var rightLegRotation: SIMD3<Float> = .zero
    var leftForearmRotation: SIMD3<Float> = .zero
    var rightForearmRotation: SIMD3<Float> = .zero
    var leftKneeRotation: SIMD3<Float> = .zero
    var rightKneeRotation: SIMD3<Float> = .zero
    
    init(modelName: String) {
        self.id = UUID()
        self.modelName = modelName
    }
}
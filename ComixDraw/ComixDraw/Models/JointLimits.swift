//
//  JointLimits.swift
//  ComixDraw
//
//  From ComixApp — realistic joint constraints for the mixamorig skeleton
//

import Foundation

class AxisRange {
    let minDegrees: Float
    let maxDegrees: Float
    init(min: Float, max: Float) {
        self.minDegrees = min
        self.maxDegrees = max
    }
}

class JointConstraints {
    let name: String
    let xRange: AxisRange?
    let yRange: AxisRange?
    let zRange: AxisRange?
    init(name: String, x: AxisRange? = nil, y: AxisRange? = nil, z: AxisRange? = nil) {
        self.name = name
        self.xRange = x
        self.yRange = y
        self.zRange = z
    }
}

struct JointRegistry {

    // MARK: - Full paths from the mixamorig skeleton
    private static let leftArmPath      = "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_LeftShoulder/mixamorig_LeftArm"
    private static let rightArmPath     = "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_RightShoulder/mixamorig_RightArm"
    private static let leftForeArmPath  = "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_LeftShoulder/mixamorig_LeftArm/mixamorig_LeftForeArm"
    private static let rightForeArmPath = "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_RightShoulder/mixamorig_RightArm/mixamorig_RightForeArm"
    private static let headPath         = "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_Neck/mixamorig_Head"
    private static let neckPath         = "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_Neck"
    private static let leftLegPath      = "mixamorig_Hips/mixamorig_LeftUpLeg"
    private static let rightLegPath     = "mixamorig_Hips/mixamorig_RightUpLeg"
    private static let leftKneePath     = "mixamorig_Hips/mixamorig_LeftUpLeg/mixamorig_LeftLeg"
    private static let rightKneePath    = "mixamorig_Hips/mixamorig_RightUpLeg/mixamorig_RightLeg"

    // MARK: - Constraints with realistic anatomical ranges
    static let leftArm = JointConstraints(
        name: leftArmPath,
        x: AxisRange(min: -90, max: 90),
        y: AxisRange(min: -180, max: 25),
        z: AxisRange(min: -15, max: 135)
    )
    static let rightArm = JointConstraints(
        name: rightArmPath,
        x: AxisRange(min: -90, max: 90),
        y: AxisRange(min: -25, max: 180),
        z: AxisRange(min: -15, max: 135)
    )
    static let leftForearm = JointConstraints(
        name: leftForeArmPath,
        x: AxisRange(min: 0, max: 145)
    )
    static let rightForearm = JointConstraints(
        name: rightForeArmPath,
        x: AxisRange(min: 0, max: 145)
    )
    static let head = JointConstraints(
        name: headPath,
        x: AxisRange(min: -45, max: 45),
        y: AxisRange(min: -60, max: 60),
        z: AxisRange(min: -30, max: 30)
    )
    static let neck = JointConstraints(
        name: neckPath,
        x: AxisRange(min: -30, max: 30),
        y: AxisRange(min: -45, max: 45),
        z: AxisRange(min: -15, max: 15)
    )
    static let leftLeg = JointConstraints(
        name: leftLegPath,
        x: AxisRange(min: 90, max: 225),
        y: AxisRange(min: -30, max: 30),
        z: AxisRange(min: -15, max: 90)
    )
    static let rightLeg = JointConstraints(
        name: rightLegPath,
        x: AxisRange(min: 90, max: 225),
        y: AxisRange(min: -30, max: 30),
        z: AxisRange(min: -90, max: 15)
    )
    static let leftKnee = JointConstraints(
        name: leftKneePath,
        x: AxisRange(min: -145, max: 0)
    )
    static let rightKnee = JointConstraints(
        name: rightKneePath,
        x: AxisRange(min: -145, max: 0)
    )

    static let allConstraints: [JointConstraints] = [
        leftArm, rightArm, head, neck,
        leftLeg, rightLeg,
        leftForearm, rightForearm,
        leftKnee, rightKnee
    ]

    static func getConstraints(for name: String) -> JointConstraints? {
        return allConstraints.first { $0.name == name }
    }
}

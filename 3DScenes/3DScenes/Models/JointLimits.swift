import Foundation

struct AxisRange {
    init() {}
}

struct JointConstraints {
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
    private static let leftArmPath =
        "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_LeftShoulder/mixamorig_LeftArm"
    private static let rightArmPath =
        "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_RightShoulder/mixamorig_RightArm"
    private static let leftForeArmPath =
        "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_LeftShoulder/mixamorig_LeftArm/mixamorig_LeftForeArm"
    private static let rightForeArmPath =
        "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_RightShoulder/mixamorig_RightArm/mixamorig_RightForeArm"
    private static let headPath =
        "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_Neck/mixamorig_Head"
    private static let neckPath =
        "mixamorig_Hips/mixamorig_Spine/mixamorig_Spine1/mixamorig_Spine2/mixamorig_Neck"
    private static let torsoPath = "mixamorig_Hips/mixamorig_Spine"
    private static let leftLegPath = "mixamorig_Hips/mixamorig_LeftUpLeg"
    private static let rightLegPath = "mixamorig_Hips/mixamorig_RightUpLeg"
    private static let leftKneePath = "mixamorig_Hips/mixamorig_LeftUpLeg/mixamorig_LeftLeg"
    private static let rightKneePath = "mixamorig_Hips/mixamorig_RightUpLeg/mixamorig_RightLeg"

    static let leftArm = JointConstraints(name: leftArmPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let rightArm = JointConstraints(name: rightArmPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let leftForearm = JointConstraints(name: leftForeArmPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let rightForearm = JointConstraints(name: rightForeArmPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let head = JointConstraints(name: headPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let neck = JointConstraints(name: neckPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let torso = JointConstraints(name: torsoPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let leftLeg = JointConstraints(name: leftLegPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let rightLeg = JointConstraints(name: rightLegPath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let leftKnee = JointConstraints(name: leftKneePath, x: AxisRange(), y: AxisRange(), z: AxisRange())
    static let rightKnee = JointConstraints(name: rightKneePath, x: AxisRange(), y: AxisRange(), z: AxisRange())
}

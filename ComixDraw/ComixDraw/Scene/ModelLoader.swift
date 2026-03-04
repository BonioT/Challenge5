//
//  ModelLoader.swift
//  ComixDraw
//
//  Loads .usd/.usdz models via SceneKit — preserves skeleton/skinner
//

import SceneKit

struct ModelLoader {

    /// Loads a .usd model from the app bundle as an SCNNode.
    /// Removes all animations so manual bone transforms work.
    static func loadModel(named name: String) -> SCNNode? {
        let extensions = ["usd", "usdz", "scn", "dae"]

        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                do {
                    let scene = try SCNScene(url: url, options: [
                        .checkConsistency: true,
                        .convertToYUp: true
                    ])
                    print("✅ Loaded model '\(name).\(ext)' via SceneKit")

                    let container = SCNNode()
                    container.name = name

                    let children = scene.rootNode.childNodes
                    for child in children {
                        child.removeFromParentNode()
                        container.addChildNode(child)
                    }

                    // CRITICAL: remove ALL animations from every node
                    // Animations override manual transforms and prevent joints from moving
                    removeAllAnimations(from: container)

                    // Debug
                    print("📐 Model hierarchy for '\(name)':")
                    printHierarchy(container)
                    printSkinnerBones(container)
                    printAllNodeNames(container)

                    return container

                } catch {
                    print("⚠️ Failed to load '\(name).\(ext)': \(error.localizedDescription)")
                }
            }
        }

        print("❌ Could not find model '\(name)' in bundle")
        return nil
    }

    /// Removes ALL animations from every node in the hierarchy.
    /// This is essential so that manual bone transforms actually take effect.
    static func removeAllAnimations(from node: SCNNode) {
        node.removeAllAnimations()
        for key in node.animationKeys {
            node.removeAnimation(forKey: key)
        }
        for child in node.childNodes {
            removeAllAnimations(from: child)
        }
    }

    /// Builds a bone-name → SCNNode lookup from the skinner(s) in the hierarchy.
    /// Returns the actual bone node instances used by the skinner for mesh deformation.
    static func buildBoneMap(from root: SCNNode) -> [String: SCNNode] {
        var boneMap: [String: SCNNode] = [:]

        root.enumerateChildNodes { node, _ in
            if let skinner = node.skinner {
                for bone in skinner.bones {
                    if let boneName = bone.name {
                        boneMap[boneName] = bone
                    }
                }
            }
        }

        // Also add all named nodes as fallback
        root.enumerateChildNodes { node, _ in
            if let name = node.name, !name.isEmpty, boneMap[name] == nil {
                boneMap[name] = node
            }
        }

        return boneMap
    }

    /// Finds a joint node by searching multiple strategies.
    static func findJoint(named jointPath: String, in root: SCNNode) -> SCNNode? {
        let jointName = jointPath.components(separatedBy: "/").last ?? jointPath

        // Strategy 1: exact name match
        if let node = root.childNode(withName: jointName, recursively: true) {
            return node
        }

        // Strategy 2: suffix match
        var found: SCNNode?
        root.enumerateChildNodes { node, stop in
            if let name = node.name, name.hasSuffix(jointName) {
                found = node
                stop.pointee = true
            }
        }
        if let f = found { return f }

        // Strategy 3: contains match
        let simpleName = jointName.replacingOccurrences(of: "mixamorig_", with: "")
        root.enumerateChildNodes { node, stop in
            if let name = node.name, name.contains(simpleName) {
                found = node
                stop.pointee = true
            }
        }
        if let f = found { return f }

        // Strategy 4: skinner bones
        root.enumerateChildNodes { node, stop in
            if let skinner = node.skinner {
                for bone in skinner.bones {
                    if let boneName = bone.name {
                        if boneName == jointName || boneName.hasSuffix(jointName) || boneName.contains(simpleName) {
                            found = bone
                            stop.pointee = true
                            return
                        }
                    }
                }
            }
        }
        return found
    }

    /// Debug: prints ALL node names in a flat list
    static func printAllNodeNames(_ root: SCNNode) {
        var names: [String] = []
        root.enumerateChildNodes { node, _ in
            if let name = node.name, !name.isEmpty {
                let geo = node.geometry != nil ? " [GEO]" : ""
                let skin = node.skinner != nil ? " [SKIN]" : ""
                names.append("  → \(name)\(geo)\(skin)")
            }
        }
        print("📋 All \(names.count) named nodes:")
        names.forEach { print($0) }
    }

    /// Debug: prints skinner bones
    private static func printSkinnerBones(_ root: SCNNode) {
        root.enumerateChildNodes { node, _ in
            if let skinner = node.skinner {
                print("🦴 Skinner on '\(node.name ?? "?")', \(skinner.bones.count) bones:")
                for bone in skinner.bones {
                    print("   🦴 \(bone.name ?? "<unnamed>")")
                }
            }
        }
    }

    /// Debug: prints hierarchy tree
    static func printHierarchy(_ node: SCNNode, indent: Int = 0) {
        let prefix = String(repeating: "  ", count: indent)
        let geo = node.geometry != nil ? " [GEO]" : ""
        let skin = node.skinner != nil ? " [SKIN]" : ""
        let anim = !node.animationKeys.isEmpty ? " [ANIM:\(node.animationKeys.count)]" : ""
        print("\(prefix)📦 \(node.name ?? "<unnamed>")\(geo)\(skin)\(anim)")
        for child in node.childNodes {
            printHierarchy(child, indent: indent + 1)
        }
    }
}

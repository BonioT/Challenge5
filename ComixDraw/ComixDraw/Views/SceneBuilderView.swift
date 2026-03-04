//
//  SceneBuilderView.swift
//  ComixDraw
//
//  Merged: side panel (ComixApp) + pose presets (Constructor) + snapshot + light + import
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct SceneBuilderView: View {

    @ObservedObject var viewModel: SceneViewModel
    @Binding var snapshot: UIImage?

    @State private var scnView: SCNView?
    @State private var showControls = true
    @State private var showImportPicker = false

    var body: some View {
        ZStack(alignment: .leading) {

            // 3D Scene
            SceneViewContainer(viewModel: viewModel, onViewReady: { view in
                self.scnView = view
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            // Toggle button
            VStack {
                Button(action: {
                    withAnimation(.spring()) { showControls.toggle() }
                }) {
                    Image(systemName: showControls ? "chevron.left.circle.fill" : "slider.horizontal.3")
                        .font(.title)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.leading, 15)
                .padding(.top, 50)
                Spacer()
            }
            .zIndex(1)

            // Side panel
            if showControls {
                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Snapshot
                        Button(action: { takeSnapshot() }) {
                            Label("Snapshot & Draw", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .padding(.top)

                        Divider()

                        // MARK: - Dummy List
                        dummyListSection

                        Divider()

                        // MARK: - Pose Presets
                        posePresetsSection

                        Divider()

                        // MARK: - Selected Dummy Controls
                        if let index = viewModel.selectedIndex {
                            dummyControls(index: index)
                        } else {
                            Text("Seleziona un dummy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .frame(width: 260)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .leading))
                .padding(.top, 110)
            }
        }
        .onChange(of: viewModel.dummies) { _, newDummies in
            for dummy in newDummies {
                viewModel.updateDummyTransform(for: dummy)
                viewModel.updateAllJoints(for: dummy)
            }
        }
        .onChange(of: viewModel.cameraAzimuth) { _, _ in viewModel.updateCamera() }
        .onChange(of: viewModel.cameraElevation) { _, _ in viewModel.updateCamera() }
        .onChange(of: viewModel.cameraDistance) { _, _ in viewModel.updateCamera() }
        .onChange(of: viewModel.lightX) { _, _ in viewModel.updateLight() }
        .onChange(of: viewModel.lightY) { _, _ in viewModel.updateLight() }
        .onChange(of: viewModel.lightZ) { _, _ in viewModel.updateLight() }
        .onChange(of: viewModel.lightIntensity) { _, _ in viewModel.updateLight() }
        .onChange(of: viewModel.showLight) { _, _ in viewModel.updateLight() }
        .onChange(of: viewModel.selectedBoneName) { _, newBone in
            guard let bone = newBone else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if leftArmBones.contains(bone) { expandLeftArm = true }
                else if rightArmBones.contains(bone) { expandRightArm = true }
                else if headBones.contains(bone) { expandHead = true }
                else if leftLegBones.contains(bone) { expandLeftLeg = true }
                else if rightLegBones.contains(bone) { expandRightLeg = true }
            }
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker { url in
                viewModel.importModel(from: url)
            }
        }
    }

    // MARK: - Sections

    private var dummyListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manichini").font(.headline)

            ForEach(viewModel.dummies) { dummy in
                Button(dummy.modelName) {
                    viewModel.selectedDummyID = dummy.id
                }
                .buttonStyle(.bordered)
                .tint(viewModel.selectedDummyID == dummy.id ? .blue : .gray)
            }

            HStack {
                Button { viewModel.addDummy() } label: {
                    Label("Aggiungi", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                if viewModel.dummies.count > 1 {
                    Button { viewModel.removeSelectedDummy() } label: {
                        Label("Rimuovi", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }

            // Import 3D object
            Button {
                showImportPicker = true
            } label: {
                Label("Importa Oggetto 3D", systemImage: "cube.transparent")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }

    private var posePresetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pose Presets").font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(SceneViewModel.PoseType.allCases, id: \.self) { pose in
                    Button(pose.rawValue) {
                        viewModel.applyPose(pose)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }

    // MARK: - Dummy Controls

    // Expanded states for each joint group
    @State private var expandTransform = true
    @State private var expandPosition = false
    @State private var expandLeftArm = false
    @State private var expandRightArm = false
    @State private var expandHead = false
    @State private var expandLeftLeg = false
    @State private var expandRightLeg = false
    @State private var expandLight = false
    @State private var expandCamera = false

    /// Which bones belong to which group
    private let leftArmBones: Set<String> = ["mixamorig_LeftArm", "mixamorig_LeftForeArm"]
    private let rightArmBones: Set<String> = ["mixamorig_RightArm", "mixamorig_RightForeArm"]
    private let headBones: Set<String> = ["mixamorig_Head", "mixamorig_Neck"]
    private let leftLegBones: Set<String> = ["mixamorig_LeftUpLeg", "mixamorig_LeftLeg"]
    private let rightLegBones: Set<String> = ["mixamorig_RightUpLeg", "mixamorig_RightLeg"]

    @ViewBuilder
    private func dummyControls(index: Int) -> some View {

        // Transform
        jointGroup(
            title: "📐 Modello",
            icon: "cube",
            isExpanded: $expandTransform,
            isActive: false
        ) {
            VStack(alignment: .leading) {
                Text("Scale: \(String(format: "%.3f", viewModel.dummies[index].scale))x").font(.caption)
                Slider(value: $viewModel.dummies[index].scale, in: 0.005...0.1)
            }
            VStack(alignment: .leading) {
                Text("Rotate Y: \(Int(viewModel.dummies[index].rotationY))°").font(.caption)
                Slider(value: $viewModel.dummies[index].rotationY, in: 0...360)
            }
        }

        // Position
        jointGroup(
            title: "📍 Posizione",
            icon: "move.3d",
            isExpanded: $expandPosition,
            isActive: false
        ) {
            VStack(alignment: .leading) {
                Text("X: \(String(format: "%.2f", viewModel.dummies[index].positionX))").font(.caption)
                Slider(value: $viewModel.dummies[index].positionX, in: -5...5)
            }
            VStack(alignment: .leading) {
                Text("Y: \(String(format: "%.2f", viewModel.dummies[index].positionY))").font(.caption)
                Slider(value: $viewModel.dummies[index].positionY, in: -2...5)
            }
            VStack(alignment: .leading) {
                Text("Z: \(String(format: "%.2f", viewModel.dummies[index].positionZ))").font(.caption)
                Slider(value: $viewModel.dummies[index].positionZ, in: -5...5)
            }
        }

        // Left Arm
        jointGroup(
            title: "💪 Braccio Sinistro",
            icon: "figure.arms.open",
            isExpanded: $expandLeftArm,
            isActive: leftArmBones.contains(viewModel.selectedBoneName ?? "")
        ) {
            jointControlSection(title: "Spalla", rotation: $viewModel.dummies[index].leftArmRotation, constraints: JointRegistry.leftArm)
            jointControlSection(title: "Gomito", rotation: $viewModel.dummies[index].leftForearmRotation, constraints: JointRegistry.leftForearm)
        }

        // Right Arm
        jointGroup(
            title: "💪 Braccio Destro",
            icon: "figure.arms.open",
            isExpanded: $expandRightArm,
            isActive: rightArmBones.contains(viewModel.selectedBoneName ?? "")
        ) {
            jointControlSection(title: "Spalla", rotation: $viewModel.dummies[index].rightArmRotation, constraints: JointRegistry.rightArm)
            jointControlSection(title: "Gomito", rotation: $viewModel.dummies[index].rightForearmRotation, constraints: JointRegistry.rightForearm)
        }

        // Head & Neck
        jointGroup(
            title: "🗣️ Testa e Collo",
            icon: "person.crop.circle",
            isExpanded: $expandHead,
            isActive: headBones.contains(viewModel.selectedBoneName ?? "")
        ) {
            jointControlSection(title: "Testa", rotation: $viewModel.dummies[index].headRotation, constraints: JointRegistry.head)
            jointControlSection(title: "Collo", rotation: $viewModel.dummies[index].neckRotation, constraints: JointRegistry.neck)
        }

        // Left Leg
        jointGroup(
            title: "🦵 Gamba Sinistra",
            icon: "figure.walk",
            isExpanded: $expandLeftLeg,
            isActive: leftLegBones.contains(viewModel.selectedBoneName ?? "")
        ) {
            jointControlSection(title: "Coscia", rotation: $viewModel.dummies[index].leftLegRotation, constraints: JointRegistry.leftLeg)
            jointControlSection(title: "Ginocchio", rotation: $viewModel.dummies[index].leftKneeRotation, constraints: JointRegistry.leftKnee)
        }

        // Right Leg
        jointGroup(
            title: "🦵 Gamba Destra",
            icon: "figure.walk",
            isExpanded: $expandRightLeg,
            isActive: rightLegBones.contains(viewModel.selectedBoneName ?? "")
        ) {
            jointControlSection(title: "Coscia", rotation: $viewModel.dummies[index].rightLegRotation, constraints: JointRegistry.rightLeg)
            jointControlSection(title: "Ginocchio", rotation: $viewModel.dummies[index].rightKneeRotation, constraints: JointRegistry.rightKnee)
        }

        // Light Controls
        jointGroup(title: "💡 Luce", icon: "light.max", isExpanded: $expandLight, isActive: false) {
            HStack {
                Text("Attiva")
                Spacer()
                Toggle("", isOn: $viewModel.showLight).labelsHidden()
            }
            if viewModel.showLight {
                VStack(alignment: .leading) {
                    Text("Intensità: \(Int(viewModel.lightIntensity))").font(.caption)
                    Slider(value: $viewModel.lightIntensity, in: 0...3000)
                }
                VStack(alignment: .leading) {
                    Text("X: \(String(format: "%.1f", viewModel.lightX))").font(.caption)
                    Slider(value: $viewModel.lightX, in: -15...15)
                }
                VStack(alignment: .leading) {
                    Text("Y: \(String(format: "%.1f", viewModel.lightY))").font(.caption)
                    Slider(value: $viewModel.lightY, in: 0...20)
                }
                VStack(alignment: .leading) {
                    Text("Z: \(String(format: "%.1f", viewModel.lightZ))").font(.caption)
                    Slider(value: $viewModel.lightZ, in: -15...15)
                }
            }
        }

        // Camera
        jointGroup(title: "📷 Camera", icon: "camera", isExpanded: $expandCamera, isActive: false) {
            VStack(alignment: .leading) {
                Text("Orizzontale: \(Int(viewModel.cameraAzimuth))°").font(.caption)
                Slider(value: $viewModel.cameraAzimuth, in: 0...360)
            }
            VStack(alignment: .leading) {
                Text("Verticale: \(Int(viewModel.cameraElevation))°").font(.caption)
                Slider(value: $viewModel.cameraElevation, in: -30...80)
            }
            VStack(alignment: .leading) {
                Text("Distanza: \(String(format: "%.2f", viewModel.cameraDistance))").font(.caption)
                Slider(value: $viewModel.cameraDistance, in: 1...20)
            }
        }

        // Reset
        Button(action: { viewModel.resetDummy(index: index) }) {
            Label("Reset Dummy", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom)
    }

    // MARK: - Collapsible Group

    @ViewBuilder
    private func jointGroup<Content: View>(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        isActive: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(isActive ? .yellow : .primary)
                        .frame(width: 20)
                    Text(title)
                        .font(.subheadline).bold()
                        .foregroundColor(isActive ? .yellow : .primary)

                    if isActive {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 8, height: 8)
                    }

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? Color.yellow.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Joint Control Section

    @ViewBuilder
    private func jointControlSection(title: String, rotation: Binding<SIMD3<Float>>, constraints: JointConstraints) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).bold()

            if let xRange = constraints.xRange {
                VStack(alignment: .leading) {
                    Text("X: \(Int(rotation.wrappedValue.x))°").font(.caption2)
                    Slider(
                        value: Binding(get: { rotation.wrappedValue.x }, set: { rotation.wrappedValue.x = $0 }),
                        in: xRange.minDegrees...xRange.maxDegrees
                    )
                }
            }
            if let yRange = constraints.yRange {
                VStack(alignment: .leading) {
                    Text("Y: \(Int(rotation.wrappedValue.y))°").font(.caption2)
                    Slider(
                        value: Binding(get: { rotation.wrappedValue.y }, set: { rotation.wrappedValue.y = $0 }),
                        in: yRange.minDegrees...yRange.maxDegrees
                    )
                }
            }
            if let zRange = constraints.zRange {
                VStack(alignment: .leading) {
                    Text("Z: \(Int(rotation.wrappedValue.z))°").font(.caption2)
                    Slider(
                        value: Binding(get: { rotation.wrappedValue.z }, set: { rotation.wrappedValue.z = $0 }),
                        in: zRange.minDegrees...zRange.maxDegrees
                    )
                }
            }
        }
    }

    // MARK: - Snapshot

    private func takeSnapshot() {
        guard let scnView else { return }
        snapshot = scnView.snapshot()
    }
}

// MARK: - Document Picker for importing 3D models

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [
            .usdz,
            UTType(filenameExtension: "usd") ?? .data,
            UTType(filenameExtension: "dae") ?? .data,
            UTType(filenameExtension: "scn") ?? .data,
            UTType(filenameExtension: "obj") ?? .data,
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onPick(url)
            }
        }
    }
}

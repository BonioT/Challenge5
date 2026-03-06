import SwiftUI

enum EditorCategory: String, CaseIterable {
    case model = "Model"
    case position = "Position"
    case torso = "Head & Body"
    case arms = "Arms & Hands"
    case legs = "Legs"
    case camera = "Camera"
    case light = "Light"

    var icon: String {
        switch self {
        case .model: return "cube.transparent"
        case .position: return "move.3d"
        case .torso: return "person.crop.circle"
        case .arms: return "hand.raised.fill"
        case .legs: return "figure.run"
        case .camera: return "camera.fill"
        case .light: return "sun.max.fill"
        }
    }
}

enum PendingSnapshotAction: Equatable {
    case saveScene
    case createSheet
}

struct SingleDummyEditorView: View {
    @ObservedObject var viewModel: SceneEditorViewModel
    @State private var selectedCategory: EditorCategory? = nil

    @State private var snapshotImage: UIImage?
    @State private var triggerSnapshot = false
    @State private var pendingAction: PendingSnapshotAction? = nil

    @State private var currentSheetId: UUID?
    @State private var showSheetsGallery = false

    @State private var isSidebarVisible = true
    @State private var isSavingAndDismissing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .leading) {
            SceneRoomViewCustomizable(
                editorState: viewModel,
                triggerSnapshot: $triggerSnapshot,
                snapshotImage: $snapshotImage
            )
            .ignoresSafeArea()

            VStack {
                HStack(alignment: .top, spacing: 0) {
                    if isSidebarVisible {
                        VStack(spacing: 6) {
                            ForEach(EditorCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }) {
                                    Image(systemName: category.icon)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .background(
                                            selectedCategory == category
                                                ? AnyShapeStyle(Color.blue)
                                                : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 3, y: 0)
                        .padding(.leading, 10)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                        if let category = selectedCategory {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 0) {
                                    HStack {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.secondary)
                                        TextField("Scene Name", text: $viewModel.sceneName)
                                            .font(.headline)
                                            .textFieldStyle(PlainTextFieldStyle())
                                    }
                                    .padding()
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                    .padding(.bottom, 10)

                                    HStack(spacing: 8) {
                                        Image(systemName: category.icon)
                                            .font(.title3)
                                        Text(category.rawValue)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)

                                    VStack(alignment: .leading, spacing: 15) {
                                        categoryControls(for: category)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 16)
                                }
                            }
                            .frame(width: 270)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.12), radius: 10, x: 3, y: 0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }

                    Spacer()
                }
                .padding(.top, 70)
                .padding(.bottom, 20)
                Spacer()
            }
            .zIndex(1)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 15) {
                    Button(action: {
                        isSavingAndDismissing = true
                        pendingAction = .saveScene
                        triggerSnapshot = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.backward")
                                .font(.headline)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.primary)
                    }

                    Button(action: {
                        withAnimation(.spring()) { isSidebarVisible.toggle() }
                    }) {
                        Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    Button(action: { showSheetsGallery = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .font(.headline)
                            Text("My Sheets")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    pendingAction = .createSheet
                    triggerSnapshot = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Convert to 2D & Draw")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                }
            }
        }
        .onChange(of: snapshotImage) { _, newValue in
            guard let image = newValue else { return }

            if pendingAction == .createSheet {
                let newSheet = DrawingSheet(id: UUID(), createdAt: Date())
                viewModel.sheets.append(newSheet)
                currentSheetId = newSheet.id
                DataManager.shared.saveSheetThumbnail(image, for: newSheet.id, in: viewModel.sceneId)
                let doc = viewModel.buildDocument()
                try? DataManager.shared.saveScene(doc, thumbnail: image)
                pendingAction = nil
            } else if pendingAction == .saveScene {
                let doc = viewModel.buildDocument()
                try? DataManager.shared.saveScene(doc, thumbnail: image)
                snapshotImage = nil
                pendingAction = nil
                if isSavingAndDismissing { dismiss() }
            }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { snapshotImage != nil && currentSheetId != nil },
                set: { if !$0 { snapshotImage = nil; currentSheetId = nil } }
            )
        ) {
            if let image = snapshotImage, let sheetId = currentSheetId {
                DrawView(backgroundImage: image, sceneId: viewModel.sceneId, sheetId: sheetId)
            }
        }
        .sheet(isPresented: $showSheetsGallery) {
            SheetsGalleryView(
                viewModel: viewModel, showSheetsGallery: $showSheetsGallery,
                onSelectSheet: { sheet in
                    currentSheetId = sheet.id
                    snapshotImage = DataManager.shared.loadSheetThumbnail(
                        for: sheet.id, in: viewModel.sceneId)
                    showSheetsGallery = false
                })
        }
    }

    @ViewBuilder
    private func categoryControls(for category: EditorCategory) -> some View {
        switch category {
        case .model:
            VStack(alignment: .leading, spacing: 15) {
                Menu {
                    Button("Add Male Dummy") { spawnObject("dummyM") }
                    Button("Add Boss") { spawnObject("boss") }
                    Button("Add Female Dummy") { spawnObject("dummyF") }
                } label: {
                    Label("Add 3D Object", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if viewModel.dummies.count > 1 {
                    Button(action: {
                        if let id = viewModel.selectedDummyID,
                            let index = viewModel.dummies.firstIndex(where: { $0.id == id })
                        {
                            viewModel.dummies.remove(at: index)
                            viewModel.selectedDummyID = viewModel.dummies.first?.id
                        }
                    }) {
                        Label("Delete Selected Object", systemImage: "trash.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("Scale: \(String(format: "%.2f", bindingForSelectedDummy().wrappedValue.scale))x")
                        .font(.caption)
                    Slider(value: bindingForSelectedDummy().scale, in: 0.1...5.0)
                }
                VStack(alignment: .leading) {
                    Text("Rotate X: \(Int(bindingForSelectedDummy().wrappedValue.rotationX))°").font(.caption)
                    Slider(value: bindingForSelectedDummy().rotationX, in: 0...360)
                }
                VStack(alignment: .leading) {
                    Text("Rotate Y: \(Int(bindingForSelectedDummy().wrappedValue.rotationY))°").font(.caption)
                    Slider(value: bindingForSelectedDummy().rotationY, in: 0...360)
                }
                VStack(alignment: .leading) {
                    Text("Rotate Z: \(Int(bindingForSelectedDummy().wrappedValue.rotationZ))°").font(.caption)
                    Slider(value: bindingForSelectedDummy().rotationZ, in: 0...360)
                }
            }

        case .position:
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text("X: \(String(format: "%.2f", bindingForSelectedDummy().wrappedValue.positionX))").font(.caption)
                    Slider(value: bindingForSelectedDummy().positionX, in: -200...200)
                }
                VStack(alignment: .leading) {
                    Text("Y: \(String(format: "%.2f", bindingForSelectedDummy().wrappedValue.positionY))").font(.caption)
                    Slider(value: bindingForSelectedDummy().positionY, in: -200...200)
                }
                VStack(alignment: .leading) {
                    Text("Z: \(String(format: "%.2f", bindingForSelectedDummy().wrappedValue.positionZ))").font(.caption)
                    Slider(value: bindingForSelectedDummy().positionZ, in: -200...200)
                }
            }

        case .torso:
            VStack(alignment: .leading, spacing: 20) {
                jointSliderGroup(title: "Torso", rotation: bindingForSelectedDummy().torsoRotation, constraints: JointRegistry.torso)
                jointSliderGroup(title: "Head", rotation: bindingForSelectedDummy().headRotation, constraints: JointRegistry.head)
                jointSliderGroup(title: "Neck", rotation: bindingForSelectedDummy().neckRotation, constraints: JointRegistry.neck)
            }

        case .arms:
            VStack(alignment: .leading, spacing: 20) {
                jointSliderGroup(title: "Left Arm", rotation: bindingForSelectedDummy().leftArmRotation, constraints: JointRegistry.leftArm)
                jointSliderGroup(title: "Left Forearm", rotation: bindingForSelectedDummy().leftForearmRotation, constraints: JointRegistry.leftForearm)
                Divider()
                jointSliderGroup(title: "Right Arm", rotation: bindingForSelectedDummy().rightArmRotation, constraints: JointRegistry.rightArm)
                jointSliderGroup(title: "Right Forearm", rotation: bindingForSelectedDummy().rightForearmRotation, constraints: JointRegistry.rightForearm)
            }

        case .legs:
            VStack(alignment: .leading, spacing: 20) {
                jointSliderGroup(title: "Left Leg", rotation: bindingForSelectedDummy().leftLegRotation, constraints: JointRegistry.leftLeg)
                jointSliderGroup(title: "Left Knee", rotation: bindingForSelectedDummy().leftKneeRotation, constraints: JointRegistry.leftKnee)
                Divider()
                jointSliderGroup(title: "Right Leg", rotation: bindingForSelectedDummy().rightLegRotation, constraints: JointRegistry.rightLeg)
                jointSliderGroup(title: "Right Knee", rotation: bindingForSelectedDummy().rightKneeRotation, constraints: JointRegistry.rightKnee)
            }

        case .camera:
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Horizontal (\(Int(viewModel.cameraAzimuth))°)").font(.caption)
                    Slider(value: $viewModel.cameraAzimuth, in: 0...360)
                }
                VStack(alignment: .leading) {
                    Text("Vertical (\(Int(viewModel.cameraElevation))°)").font(.caption)
                    Slider(value: $viewModel.cameraElevation, in: -30...80)
                }
                VStack(alignment: .leading) {
                    Text("Distance: \(String(format: "%.2f", viewModel.cameraDistance))").font(.caption)
                    Slider(value: $viewModel.cameraDistance, in: 1...20.0)
                }
                Divider()
                Text("Camera Target").font(.caption).bold()
                VStack(alignment: .leading) {
                    Text("X: \(String(format: "%.1f", viewModel.cameraTargetX))").font(.caption)
                    Slider(value: $viewModel.cameraTargetX, in: -5...5)
                }
                VStack(alignment: .leading) {
                    Text("Y: \(String(format: "%.1f", viewModel.cameraTargetY))").font(.caption)
                    Slider(value: $viewModel.cameraTargetY, in: -5...5)
                }
                VStack(alignment: .leading) {
                    Text("Z: \(String(format: "%.1f", viewModel.cameraTargetZ))").font(.caption)
                    Slider(value: $viewModel.cameraTargetZ, in: -5...5)
                }
            }

        case .light:
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Position X: \(String(format: "%.1f", viewModel.lightPosition.x))").font(.caption)
                    Slider(value: $viewModel.lightPosition.x, in: -10...10)
                }
                VStack(alignment: .leading) {
                    Text("Position Y: \(String(format: "%.1f", viewModel.lightPosition.y))").font(.caption)
                    Slider(value: $viewModel.lightPosition.y, in: -10...20)
                }
                VStack(alignment: .leading) {
                    Text("Position Z: \(String(format: "%.1f", viewModel.lightPosition.z))").font(.caption)
                    Slider(value: $viewModel.lightPosition.z, in: -10...10)
                }
            }
        }

        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                viewModel.resetDummy()
            }
        }) {
            Label("Reset Dummy", systemImage: "arrow.counterclockwise")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.bottom)
    }

    @ViewBuilder
    private func jointSliderGroup(
        title: String, rotation: Binding<SIMD3<Float>>, constraints: JointConstraints
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).bold()

            if constraints.xRange != nil {
                VStack(alignment: .leading) {
                    Text("X: \(Int(rotation.wrappedValue.x))°").font(.caption2)
                    Slider(
                        value: Binding(get: { rotation.wrappedValue.x }, set: { rotation.wrappedValue.x = $0 }),
                        in: 0...360
                    )
                }
            }
            if constraints.yRange != nil {
                VStack(alignment: .leading) {
                    Text("Y: \(Int(rotation.wrappedValue.y))°").font(.caption2)
                    Slider(
                        value: Binding(get: { rotation.wrappedValue.y }, set: { rotation.wrappedValue.y = $0 }),
                        in: 0...360
                    )
                }
            }
            if constraints.zRange != nil {
                VStack(alignment: .leading) {
                    Text("Z: \(Int(rotation.wrappedValue.z))°").font(.caption2)
                    Slider(
                        value: Binding(get: { rotation.wrappedValue.z }, set: { rotation.wrappedValue.z = $0 }),
                        in: 0...360
                    )
                }
            }
        }
    }

    private func bindingForSelectedDummy() -> Binding<DummyState> {
        Binding<DummyState>(
            get: {
                if let id = viewModel.selectedDummyID,
                    let dummy = viewModel.dummies.first(where: { $0.id == id })
                {
                    return dummy
                }
                return viewModel.dummies.first ?? DummyState(modelName: "dummyM")
            },
            set: { newValue in
                if let id = viewModel.selectedDummyID,
                    let index = viewModel.dummies.firstIndex(where: { $0.id == id })
                {
                    viewModel.dummies[index] = newValue
                } else if !viewModel.dummies.isEmpty {
                    viewModel.dummies[0] = newValue
                }
            }
        )
    }

    private func spawnObject(_ identifier: String) {
        let newObj = DummyState(modelName: identifier)
        viewModel.dummies.append(newObj)
        viewModel.selectedDummyID = newObj.id
    }
}

struct SheetsGalleryView: View {
    @ObservedObject var viewModel: SceneEditorViewModel
    @Binding var showSheetsGallery: Bool
    var onSelectSheet: (DrawingSheet) -> Void

    let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.sheets.isEmpty {
                    Text("No saved sheets yet.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.sheets) { sheet in
                            VStack {
                                if let image = DataManager.shared.loadSheetThumbnail(
                                    for: sheet.id, in: viewModel.sceneId)
                                {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                        .cornerRadius(8)
                                        .shadow(radius: 4)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 120)
                                        .cornerRadius(8)
                                        .overlay(Text("No Image").foregroundColor(.secondary))
                                }

                                Text(sheet.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .onTapGesture { onSelectSheet(sheet) }
                            .contextMenu {
                                Button(role: .destructive) {
                                    DataManager.shared.deleteSheet(id: sheet.id, in: viewModel.sceneId)
                                    viewModel.sheets.removeAll(where: { $0.id == sheet.id })
                                    let doc = viewModel.buildDocument()
                                    try? DataManager.shared.saveScene(doc)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Saved Sheets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSheetsGallery = false }
                }
            }
        }
    }
}

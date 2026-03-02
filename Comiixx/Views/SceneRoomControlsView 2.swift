//
//  SceneRoomControlsView 2.swift
//  Comiixx
//
//  Created by Pierluigi De Meo on 26/02/26.
//
import SwiftUI

struct SceneRoomControlsView: View {
    @State private var dummies: [DummyState] = [DummyState(modelName: "seahorse")]
    @State private var selectedDummyID: UUID?
    @State private var cameraDistance: Float = 4.27
    @State private var cameraAzimuth: Float = 0.0
    @State private var cameraElevation: Float = 20.6
    @State private var showControls = true

    private var selectedIndex: Int? {
        dummies.firstIndex(where: { $0.id == selectedDummyID })
    }

    var body: some View {
        ZStack(alignment: .leading) {
            SceneRoomViewCustomizable(
                dummies: $dummies,
                cameraDistance: $cameraDistance,
                cameraAzimuth: $cameraAzimuth,
                cameraElevation: $cameraElevation
            )

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

            if showControls {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Dummies").font(.headline).padding(.top)

                        ForEach(dummies) { dummy in
                            Button(dummy.modelName) {
                                selectedDummyID = dummy.id
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedDummyID == dummy.id ? .blue : .gray)
                        }

                        HStack {
                            Button { addDummy() } label: {
                                Label("Aggiungi", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)

                            if dummies.count > 1 {
                                Button { removeSelected() } label: {
                                    Label("Rimuovi", systemImage: "trash")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        }

                        Divider()

                        if let index = selectedIndex {
                            dummyControls(index: index)
                        } else {
                            Text("Seleziona un dummy").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .frame(width: 250)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .leading))
                .padding(.top, 110)
            }
        }
        .onAppear { selectedDummyID = dummies.first?.id }
    }

    @ViewBuilder
    private func dummyControls(index: Int) -> some View {
        // Model transform
        VStack(alignment: .leading, spacing: 15) {
            Text("Modello").font(.subheadline).bold()

            VStack(alignment: .leading) {
                Text("Scale: \(String(format: "%.2f", dummies[index].scale))x").font(.caption)
                Slider(value: $dummies[index].scale, in: 0.1...3.0)
            }
            VStack(alignment: .leading) {
                Text("Rotate Y: \(Int(dummies[index].rotationY))°").font(.caption)
                Slider(value: $dummies[index].rotationY, in: 0...360)
            }
        }

        Divider()

        // Position
        VStack(alignment: .leading, spacing: 15) {
            Text("Posizione").font(.subheadline).bold()
            VStack(alignment: .leading) {
                Text("X: \(String(format: "%.2f", dummies[index].positionX))").font(.caption)
                Slider(value: $dummies[index].positionX, in: -5...5)
            }
            VStack(alignment: .leading) {
                Text("Y: \(String(format: "%.2f", dummies[index].positionY))").font(.caption)
                Slider(value: $dummies[index].positionY, in: -2...5)
            }
            VStack(alignment: .leading) {
                Text("Z: \(String(format: "%.2f", dummies[index].positionZ))").font(.caption)
                Slider(value: $dummies[index].positionZ, in: -5...5)
            }
        }

        Divider()

        // Upper Limbs
        VStack(alignment: .leading, spacing: 15) {
            Text("Arti Superiori").font(.subheadline).bold()
            jointControlSection(title: "Braccio Sinistro",  rotation: $dummies[index].leftArmRotation,     constraints: JointRegistry.leftArm)
            jointControlSection(title: "Gomito Sinistro",   rotation: $dummies[index].leftForearmRotation,  constraints: JointRegistry.leftForearm)
            Divider()
            jointControlSection(title: "Braccio Destro",    rotation: $dummies[index].rightArmRotation,    constraints: JointRegistry.rightArm)
            jointControlSection(title: "Gomito Destro",     rotation: $dummies[index].rightForearmRotation, constraints: JointRegistry.rightForearm)
        }

        Divider()

        // Head and Neck
        VStack(alignment: .leading, spacing: 15) {
            Text("Testa e Collo").font(.subheadline).bold()
            jointControlSection(title: "Testa", rotation: $dummies[index].headRotation, constraints: JointRegistry.head)
            Divider()
            jointControlSection(title: "Collo", rotation: $dummies[index].neckRotation, constraints: JointRegistry.neck)
        }

        Divider()

        // Lower Limbs
        VStack(alignment: .leading, spacing: 15) {
            Text("Arti Inferiori").font(.subheadline).bold()
            jointControlSection(title: "Gamba Sinistra",     rotation: $dummies[index].leftLegRotation,   constraints: JointRegistry.leftLeg)
            jointControlSection(title: "Ginocchio Sinistro", rotation: $dummies[index].leftKneeRotation,  constraints: JointRegistry.leftKnee)
            Divider()
            jointControlSection(title: "Gamba Destra",       rotation: $dummies[index].rightLegRotation,  constraints: JointRegistry.rightLeg)
            jointControlSection(title: "Ginocchio Destro",   rotation: $dummies[index].rightKneeRotation, constraints: JointRegistry.rightKnee)
        }

        Divider()

        // Camera
        VStack(alignment: .leading, spacing: 15) {
            Text("Camera").font(.subheadline).bold()
            VStack(alignment: .leading) {
                Text("Orizzontale: \(Int(cameraAzimuth))°").font(.caption)
                Slider(value: $cameraAzimuth, in: 0...360)
            }
            VStack(alignment: .leading) {
                Text("Verticale: \(Int(cameraElevation))°").font(.caption)
                Slider(value: $cameraElevation, in: -30...80)
            }
            VStack(alignment: .leading) {
                Text("Distanza: \(String(format: "%.2f", cameraDistance))").font(.caption)
                Slider(value: $cameraDistance, in: 1...10)
            }
        }

        Divider()

        // Reset
        Button(action: { resetDummy(index: index) }) {
            Label("Reset Dummy", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom)
    }

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

    private func addDummy() {
        var newDummy = DummyState(modelName: "seahorse")
        newDummy.positionX = Float(dummies.count) * 1.5  // offset so they don't overlap
        dummies.append(newDummy)
        selectedDummyID = newDummy.id
    }

    private func removeSelected() {
        guard let id = selectedDummyID else { return }
        dummies.removeAll { $0.id == id }
        selectedDummyID = dummies.first?.id
    }

    private func resetDummy(index: Int) {
        withAnimation(.spring()) {
            dummies[index].scale = 1.0
            dummies[index].rotationY = 0.0
            dummies[index].positionX = Float(index) * 1.5
            dummies[index].positionY = 0.0
            dummies[index].positionZ = 0.0
            dummies[index].leftArmRotation = .zero
            dummies[index].rightArmRotation = .zero
            dummies[index].headRotation = .zero
            dummies[index].neckRotation = .zero
            dummies[index].leftLegRotation = .zero
            dummies[index].rightLegRotation = .zero
            dummies[index].leftForearmRotation = .zero
            dummies[index].rightForearmRotation = .zero
            dummies[index].leftKneeRotation = .zero
            dummies[index].rightKneeRotation = .zero
        }
    }
}

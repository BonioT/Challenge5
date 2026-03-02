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

            // Toggle button (unchanged)

            if showControls {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Dummies").font(.headline).padding(.top)

                        // Dummy selector
                        ForEach(dummies) { dummy in
                            Button(dummy.modelName) {
                                selectedDummyID = dummy.id
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedDummyID == dummy.id ? .blue : .gray)
                        }

                        // Add / Remove
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

                        // Controls for selected dummy
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
        // Scale, rotation, position sliders bound to dummies[index]
        VStack(alignment: .leading, spacing: 15) {
            Text("Modello").font(.subheadline).bold()
            Slider(value: $dummies[index].scale, in: 0.1...3.0)
            Slider(value: $dummies[index].rotationY, in: 0...360)
        }

        Divider()

        jointControlSection(title: "Braccio Sinistro",  rotation: $dummies[index].leftArmRotation,     constraints: JointRegistry.leftArm)
        jointControlSection(title: "Braccio Destro",    rotation: $dummies[index].rightArmRotation,    constraints: JointRegistry.rightArm)
        // ... rest of joints
    }

    private func addDummy() {
        let newDummy = DummyState(modelName: "seahorse") // or let user pick
        dummies.append(newDummy)
        selectedDummyID = newDummy.id
    }

    private func removeSelected() {
        guard let id = selectedDummyID else { return }
        dummies.removeAll { $0.id == id }
        selectedDummyID = dummies.first?.id
    }
    
    @ViewBuilder
    private func jointControlSection(title: String, rotation: Binding<SIMD3<Float>>, constraints: JointConstraints) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).bold()
            
            if let xRange = constraints.xRange {
                VStack(alignment: .leading) {
                    Text("X: \(Int(rotation.wrappedValue.x))°").font(.caption2)
                    Slider(value: Binding(get: { rotation.wrappedValue.x }, set: { rotation.wrappedValue.x = $0 }),
                           in: xRange.minDegrees...xRange.maxDegrees)
                }
            }
            if let yRange = constraints.yRange {
                VStack(alignment: .leading) {
                    Text("Y: \(Int(rotation.wrappedValue.y))°").font(.caption2)
                    Slider(value: Binding(get: { rotation.wrappedValue.y }, set: { rotation.wrappedValue.y = $0 }),
                           in: yRange.minDegrees...yRange.maxDegrees)
                }
            }
            if let zRange = constraints.zRange {
                VStack(alignment: .leading) {
                    Text("Z: \(Int(rotation.wrappedValue.z))°").font(.caption2)
                    Slider(value: Binding(get: { rotation.wrappedValue.z }, set: { rotation.wrappedValue.z = $0 }),
                           in: zRange.minDegrees...zRange.maxDegrees)
                }
            }
        }
    }
}

//
//  DrawView.swift
//  ComixDraw
//
//  From Constructor — PencilKit canvas with background snapshot and opacity controls
//

import SwiftUI
import PencilKit

struct DrawView: View {
    let backgroundImage: UIImage

    @State private var canvasView = PKCanvasView()
    @State private var backgroundOpacity: Double = 0.35
    @State private var showBackground: Bool = true
    @State private var useGrayscale: Bool = false

    private var displayImage: UIImage {
        useGrayscale ? backgroundImage.toGrayscale() : backgroundImage
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // White paper
                Color.white.ignoresSafeArea()

                if showBackground {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .opacity(backgroundOpacity)
                        .blendMode(.normal)
                        .allowsHitTesting(false)
                        .padding(12)
                }

                PencilKitCanvas(canvasView: $canvasView)
                    .padding(12)
            }

            // Controls
            HStack(spacing: 16) {
                Toggle("Mostra snapshot", isOn: $showBackground)
                    .toggleStyle(.switch)

                HStack {
                    Text("Opacità")
                    Slider(value: $backgroundOpacity, in: 0...1)
                        .frame(width: 160)
                }
                .opacity(showBackground ? 1 : 0.3)
                .disabled(!showBackground)

                Toggle("B/N", isOn: $useGrayscale)
                    .toggleStyle(.switch)
                    .opacity(showBackground ? 1 : 0.3)
                    .disabled(!showBackground)

                Spacer()

                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Draw Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PencilKit UIViewRepresentable

struct PencilKitCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        // Create and RETAIN the tool picker in the coordinator
        let toolPicker = PKToolPicker()
        context.coordinator.toolPicker = toolPicker

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Ensure tool picker remains visible
        if let toolPicker = context.coordinator.toolPicker {
            if !uiView.isFirstResponder {
                toolPicker.setVisible(true, forFirstResponder: uiView)
                toolPicker.addObserver(uiView)
                uiView.becomeFirstResponder()
            }
        }
    }

    class Coordinator {
        var toolPicker: PKToolPicker?
    }
}

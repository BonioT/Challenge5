import Combine
import PencilKit
import SwiftUI

class DrawViewModel: ObservableObject {
    @Published var canvasView = PKCanvasView()
    @Published var backgroundOpacity: Double = 0.5
    @Published var showBackground: Bool = true

    func saveDrawing(for sheetId: UUID, in sceneId: UUID) {
        let drawingData = canvasView.drawing.dataRepresentation()
        DataManager.shared.saveSheetDrawing(drawingData, for: sheetId, in: sceneId)
    }

    func loadDrawing(for sheetId: UUID, in sceneId: UUID) {
        if let existingDrawing = DataManager.shared.loadSheetDrawing(for: sheetId, in: sceneId) {
            canvasView.drawing = existingDrawing
        }
    }
}

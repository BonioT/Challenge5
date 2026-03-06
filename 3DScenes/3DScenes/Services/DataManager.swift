import Foundation
import PencilKit
import SwiftUI

class DataManager {
    static let shared = DataManager()

    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var scenesDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("Scenes", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func saveScene(_ scene: SceneDocument, thumbnail: UIImage? = nil) throws {
        let jsonURL = scenesDirectory.appendingPathComponent("\(scene.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(scene)
        try data.write(to: jsonURL)

        if let thumbnail = thumbnail, let pngData = thumbnail.pngData() {
            let thumbURL = scenesDirectory.appendingPathComponent("\(scene.id.uuidString)-thumb.png")
            try pngData.write(to: thumbURL)
        }
    }

    func fetchScenes() -> [SceneDocument] {
        var scenes: [SceneDocument] = []
        do {
            let files = try fileManager.contentsOfDirectory(at: scenesDirectory, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            for fileURL in files where fileURL.pathExtension == "json" {
                let data = try Data(contentsOf: fileURL)
                let scene = try decoder.decode(SceneDocument.self, from: data)
                scenes.append(scene)
            }
        } catch {
            print("Error fetching scenes: \(error.localizedDescription)")
        }
        return scenes.sorted { $0.lastModified > $1.lastModified }
    }

    func deleteScene(id: UUID) {
        let files = try? fileManager.contentsOfDirectory(at: scenesDirectory, includingPropertiesForKeys: nil)
        for file in files ?? [] where file.lastPathComponent.hasPrefix(id.uuidString) {
            try? fileManager.removeItem(at: file)
        }
    }

    func loadThumbnail(for id: UUID) -> UIImage? {
        let thumbURL = scenesDirectory.appendingPathComponent("\(id.uuidString)-thumb.png")
        guard let data = try? Data(contentsOf: thumbURL) else { return nil }
        return UIImage(data: data)
    }

    func saveSheetThumbnail(_ thumbnail: UIImage, for sheetId: UUID, in sceneId: UUID) {
        if let pngData = thumbnail.pngData() {
            let thumbURL = scenesDirectory.appendingPathComponent("\(sceneId.uuidString)-\(sheetId.uuidString)-thumb.png")
            try? pngData.write(to: thumbURL)
        }
    }

    func saveSheetDrawing(_ drawingData: Data, for sheetId: UUID, in sceneId: UUID) {
        let pkURL = scenesDirectory.appendingPathComponent("\(sceneId.uuidString)-\(sheetId.uuidString)-drawing.data")
        try? drawingData.write(to: pkURL)
    }

    func loadSheetThumbnail(for sheetId: UUID, in sceneId: UUID) -> UIImage? {
        let thumbURL = scenesDirectory.appendingPathComponent("\(sceneId.uuidString)-\(sheetId.uuidString)-thumb.png")
        guard let data = try? Data(contentsOf: thumbURL) else { return nil }
        return UIImage(data: data)
    }

    func loadSheetDrawing(for sheetId: UUID, in sceneId: UUID) -> PKDrawing? {
        let pkURL = scenesDirectory.appendingPathComponent("\(sceneId.uuidString)-\(sheetId.uuidString)-drawing.data")
        guard let data = try? Data(contentsOf: pkURL) else { return nil }
        return try? PKDrawing(data: data)
    }

    func deleteSheet(id sheetId: UUID, in sceneId: UUID) {
        let thumbURL = scenesDirectory.appendingPathComponent("\(sceneId.uuidString)-\(sheetId.uuidString)-thumb.png")
        let pkURL = scenesDirectory.appendingPathComponent("\(sceneId.uuidString)-\(sheetId.uuidString)-drawing.data")
        try? fileManager.removeItem(at: thumbURL)
        try? fileManager.removeItem(at: pkURL)
    }
}

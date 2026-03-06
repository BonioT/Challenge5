import Combine
import Foundation

class HomeViewModel: ObservableObject {
    @Published var savedScenes: [SceneDocument] = []

    init() {
        fetchScenes()
    }

    func fetchScenes() {
        savedScenes = DataManager.shared.fetchScenes()
    }

    func deleteScene(id: UUID) {
        DataManager.shared.deleteScene(id: id)
        fetchScenes()
    }
}

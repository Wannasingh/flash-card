import Foundation
import WidgetKit

class WidgetDataStore {
    static let shared = WidgetDataStore()
    private let suiteName = "group.wannasingh.dev.Pream-Flash-Card"
    private let defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: suiteName)
    }
    
    func saveDueCardsCount(_ count: Int) {
        defaults?.set(count, forKey: "dueCardsCount")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func saveStreakCount(_ days: Int) {
        defaults?.set(days, forKey: "streakCount")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func getDueCardsCount() -> Int {
        return defaults?.integer(forKey: "dueCardsCount") ?? 0
    }
    
    func getStreakCount() -> Int {
        return defaults?.integer(forKey: "streakCount") ?? 0
    }
}

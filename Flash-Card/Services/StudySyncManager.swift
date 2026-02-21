import Foundation

struct PendingReview: Codable, Equatable {
    let cardId: Int
    let quality: Int
    let timestamp: Date
}

class StudySyncManager {
    static let shared = StudySyncManager()
    private let queueKey = "pendingStudyReviewsQueue"
    private let api = StudyAPI.shared
    private let tokenStore = KeychainStore.shared
    
    private init() {}
    
    func queueReview(cardId: Int, quality: Int) {
        var queue = getQueue()
        // If a review for the same card is already queued, update it to the latest quality instead of duplicating
        if let index = queue.firstIndex(where: { $0.cardId == cardId }) {
            queue[index] = PendingReview(cardId: cardId, quality: quality, timestamp: Date())
        } else {
            queue.append(PendingReview(cardId: cardId, quality: quality, timestamp: Date()))
        }
        saveQueue(queue)
        print("Queued review for card \(cardId) offline.")
    }
    
    func syncPendingReviews() async {
        let queue = getQueue()
        guard !queue.isEmpty, let token = try? tokenStore.getString(forKey: "accessToken") else { return }
        
        print("Attempting to sync \(queue.count) pending reviews...")
        var successfullySyncedCardIds: Set<Int> = []
        
        for review in queue {
            do {
                try await api.submitReview(token: token, cardId: review.cardId, quality: review.quality)
                successfullySyncedCardIds.insert(review.cardId)
                
                // Update Streak for Widget (Simple logic: if a review is synced, record today as active)
                updateStreak()
            } catch {

                print("Failed to sync queued review for card \(review.cardId): \(error)")
                // Stop trying the rest if the network is still completely down to save battery/bandwidth
                break
            }
        }
        
        // Remove successfully synced items
        if !successfullySyncedCardIds.isEmpty {
            let remainingQueue = queue.filter { !successfullySyncedCardIds.contains($0.cardId) }
            saveQueue(remainingQueue)
            print("Successfully synced \(successfullySyncedCardIds.count) offline reviews. Remaining in queue: \(remainingQueue.count)")
        }
    }
    
    // MARK: - Local Storage Helpers
    
    private func getQueue() -> [PendingReview] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([PendingReview].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveQueue(_ queue: [PendingReview]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
    
    private func updateStreak() {
        let lastDateKey = "lastStudyDate"
        let currentStreakKey = "streakCount"
        
        let now = Date()
        let calendar = Calendar.current
        
        // Use standard UserDefaults for simple persistence, but sync to WidgetDataStore
        let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date
        var currentStreak = WidgetDataStore.shared.getStreakCount()
        
        if let last = lastDate {
            if calendar.isDateInYesterday(last) {
                // Studied yesterday, increment streak
                currentStreak += 1
            } else if calendar.isDateInToday(last) {
                // Already studied today, skip
                return
            } else {
                // Missed days, reset
                currentStreak = 1
            }
        } else {
            // First time
            currentStreak = 1
        }
        
        UserDefaults.standard.set(now, forKey: lastDateKey)
        WidgetDataStore.shared.saveStreakCount(currentStreak)
    }
}


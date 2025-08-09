import Foundation
import UIKit

// MARK: - Event Model
struct Event: Identifiable, Hashable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let title: String
    let color: UIColor
    
    init(startDate: Date, endDate: Date, title: String, color: UIColor = .systemBlue) {
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.color = color
    }
    
    /// Check if event occurs on a specific date
    func occursOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let eventStartDay = calendar.startOfDay(for: startDate)
        let eventEndDay = calendar.startOfDay(for: endDate)
        let checkDay = calendar.startOfDay(for: date)
        
        return checkDay >= eventStartDay && checkDay <= eventEndDay
    }
    
    /// Get the portion of the event that falls on a specific date
    func portionOn(date: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        guard occursOn(date: date) else { return nil }
        
        let eventStart = max(startDate, dayStart)
        let eventEnd = min(endDate, dayEnd)
        
        return (start: eventStart, end: eventEnd)
    }
}
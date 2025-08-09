import Foundation
import SwiftUI
import Combine

// MARK: - Publisher Extensions for Bindings
extension Published.Publisher where Value: Equatable {
    var publisher: AnyPublisher<Value, Never> {
        self.eraseToAnyPublisher()
    }
}

extension Binding {
    var publisher: AnyPublisher<Value, Never> {
        Just(wrappedValue)
            .merge(with: self.projectedValue.publisher)
            .removeDuplicates { $0 as AnyObject === $1 as AnyObject }
            .eraseToAnyPublisher()
    }
}

// MARK: - Date Extensions
extension Date {
    /// Get the start of the week for this date
    func startOfWeek(weekStartsOnMonday: Bool = true) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        
        let daysToSubtract = weekStartsOnMonday ? 
            (weekday == 1 ? 6 : weekday - 2) : 
            (weekday - 1)
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: self))!
    }
    
    /// Get the end of the week for this date
    func endOfWeek(weekStartsOnMonday: Bool = true) -> Date {
        let calendar = Calendar.current
        let startOfWeek = self.startOfWeek(weekStartsOnMonday: weekStartsOnMonday)
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
    }
    
    /// Get the start of the month for this date
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }
    
    /// Get the end of the month for this date
    var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
    }
    
    /// Check if this date is the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    /// Get hour component as CGFloat for positioning calculations
    var hourFloat: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        return CGFloat(hour) + CGFloat(minute) / 60.0
    }
}

// MARK: - Color Extensions
extension Color {
    /// Initialize Color from UIColor
    init(uiColor: UIColor) {
        self.init(uiColor)
    }
}

// MARK: - Calendar Utilities
struct CalendarUtilities {
    /// Generate a range of dates between two dates
    static func dateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return dates
    }
    
    /// Get the first day of the week containing the given date
    static func weekStart(for date: Date, weekStartsOnMonday: Bool = true) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        let daysToSubtract = weekStartsOnMonday ? 
            (weekday == 1 ? 6 : weekday - 2) : 
            (weekday - 1)
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: date))!
    }
    
    /// Get all weeks in a month
    static func weeksInMonth(_ date: Date, weekStartsOnMonday: Bool = true) -> [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        
        let firstWeekStart = weekStart(for: monthInterval.start, weekStartsOnMonday: weekStartsOnMonday)
        let lastWeekStart = weekStart(for: monthInterval.end, weekStartsOnMonday: weekStartsOnMonday)
        
        var weeks: [Date] = []
        var currentWeek = firstWeekStart
        
        while currentWeek <= lastWeekStart {
            weeks.append(currentWeek)
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) else {
                break
            }
            currentWeek = nextWeek
        }
        
        return weeks
    }
}

// MARK: - Performance Optimizations
/// A view modifier that helps with performance by reducing unnecessary redraws
struct PerformanceOptimized: ViewModifier {
    let id: AnyHashable
    
    func body(content: Content) -> some View {
        content
            .id(id)
            .drawingGroup() // Optimize for frequent redraws
    }
}

extension View {
    func optimizePerformance(id: AnyHashable) -> some View {
        modifier(PerformanceOptimized(id: id))
    }
}

// MARK: - Gesture Recognizer Helpers
class PinchGestureCoordinator: NSObject, ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var isActive = false
    
    private var initialScale: CGFloat = 1.0
    
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialScale = scale
            isActive = true
        case .changed:
            scale = initialScale * gesture.scale
        case .ended, .cancelled:
            isActive = false
        default:
            break
        }
    }
}

// MARK: - Animation Helpers
extension Animation {
    static let calendarTransition = Animation.easeInOut(duration: 0.3)
    static let eventLayout = Animation.easeOut(duration: 0.2)
    static let zoomGesture = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Accessibility Support
extension View {
    func calendarAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
}

// MARK: - Memory Management Helpers
class WeakReference<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

/// A cache that automatically removes entries when memory pressure is high
class MemoryAwareCache<Key: Hashable, Value: AnyObject> {
    private var cache: [Key: WeakReference<Value>] = [:]
    private let queue = DispatchQueue(label: "calendar.cache", attributes: .concurrent)
    
    func set(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) {
            self.cache[key] = WeakReference(value)
        }
    }
    
    func get(for key: Key) -> Value? {
        queue.sync {
            return cache[key]?.value
        }
    }
    
    func removeExpiredEntries() {
        queue.async(flags: .barrier) {
            self.cache = self.cache.compactMapValues { ref in
                ref.value != nil ? ref : nil
            }
        }
    }
}
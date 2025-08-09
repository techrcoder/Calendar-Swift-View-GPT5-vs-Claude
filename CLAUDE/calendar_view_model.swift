import Foundation
import Combine
import SwiftUI

// MARK: - Calendar Configuration
struct CalendarConfiguration {
    let weekStartsOnMonday: Bool
    let hourHeight: CGFloat
    let minHourHeight: CGFloat
    let maxHourHeight: CGFloat
    let bufferWeeks: Int // How many weeks to load ahead/behind
    
    static let `default` = CalendarConfiguration(
        weekStartsOnMonday: true,
        hourHeight: 60.0,
        minHourHeight: 20.0,
        maxHourHeight: 120.0,
        bufferWeeks: 3
    )
}

// MARK: - Calendar View Model
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var hourHeight: CGFloat
    @Published var isMonthViewExpanded = false
    @Published var currentTime = Date()
    
    private var eventCache: [String: [Event]] = [:]
    private var allEvents: [Event] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentTimeTimer: Timer?
    
    let configuration: CalendarConfiguration
    
    init(events: [Event] = [], configuration: CalendarConfiguration = .default) {
        self.allEvents = events
        self.configuration = configuration
        self.hourHeight = configuration.hourHeight
        
        setupCurrentTimeTimer()
        preloadEvents()
    }
    
    deinit {
        currentTimeTimer?.invalidate()
    }
    
    // MARK: - Current Time Updates
    private func setupCurrentTimeTimer() {
        // Update current time every minute
        currentTimeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = Date()
            }
        }
    }
    
    // MARK: - Event Management
    func updateEvents(_ events: [Event]) {
        allEvents = events
        eventCache.removeAll()
        preloadEvents()
    }
    
    private func preloadEvents() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        
        // Load events for current week ± buffer weeks
        for weekOffset in -configuration.bufferWeeks...configuration.bufferWeeks {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) {
                loadEventsForWeek(startingAt: weekStart)
            }
        }
    }
    
    private func loadEventsForWeek(startingAt weekStart: Date) {
        let calendar = Calendar.current
        
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            loadEventsForDay(day)
        }
    }
    
    private func loadEventsForDay(_ date: Date) {
        let key = dayKey(for: date)
        
        // Skip if already cached
        guard eventCache[key] == nil else { return }
        
        let dayEvents = allEvents.filter { $0.occursOn(date: date) }
        eventCache[key] = dayEvents
    }
    
    func eventsForDay(_ date: Date) -> [Event] {
        let key = dayKey(for: date)
        
        // Load if not cached
        if eventCache[key] == nil {
            loadEventsForDay(date)
        }
        
        return eventCache[key] ?? []
    }
    
    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Date Navigation
    func selectDate(_ date: Date) {
        selectedDate = date
        
        // Preload events around the new selected date
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        
        for weekOffset in -1...1 {
            if let targetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: weekStart) {
                loadEventsForWeek(startingAt: targetWeek)
            }
        }
    }
    
    func moveToNextDay() {
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            selectDate(nextDay)
        }
    }
    
    func moveToPreviousDay() {
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            selectDate(previousDay)
        }
    }
    
    func moveToToday() {
        selectDate(Date())
    }
    
    // MARK: - Zoom Management
    func updateZoom(_ scale: CGFloat) {
        let newHeight = configuration.hourHeight * scale
        hourHeight = max(configuration.minHourHeight, 
                        min(configuration.maxHourHeight, newHeight))
    }
    
    // MARK: - Month View
    func toggleMonthView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isMonthViewExpanded.toggle()
        }
    }
    
    // MARK: - Utility
    var isSelectedDateToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }
    
    func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
}
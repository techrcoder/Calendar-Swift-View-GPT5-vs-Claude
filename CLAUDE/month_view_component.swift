import SwiftUI

// MARK: - Month View Component
struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var currentMonthOffset: Int = 0
    
    private let calendar = Calendar.current
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $currentMonthOffset) {
                ForEach(-12...12, id: \.self) { monthOffset in
                    MonthGridView(
                        viewModel: viewModel,
                        monthOffset: monthOffset,
                        geometry: geometry
                    )
                    .tag(monthOffset)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentMonthOffset)
        }
        .onAppear {
            currentMonthOffset = 0
        }
        .onChange(of: viewModel.selectedDate) { newDate in
            updateCurrentMonthOffset(for: newDate)
        }
    }
    
    private func updateCurrentMonthOffset(for date: Date) {
        let today = Date()
        let monthsDifference = calendar.dateComponents([.month], from: today, to: date).month ?? 0
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonthOffset = monthsDifference
        }
    }
}

// MARK: - Month Grid View
struct MonthGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let monthOffset: Int
    let geometry: GeometryProxy
    
    private let calendar = Calendar.current
    
    private var monthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else {
            return []
        }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Get first day of the week for the month
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let startOffset = (firstWeekday - (viewModel.configuration.weekStartsOnMonday ? 2 : 1) + 7) % 7
        
        // Calculate total days needed (42 = 6 weeks * 7 days)
        let totalDays = 42
        var days: [Date?] = []
        
        // Add leading empty days
        for _ in 0..<startOffset {
            days.append(nil)
        }
        
        // Add all days in the month
        var currentDate = monthStart
        while currentDate < monthEnd {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Add trailing empty days to fill the grid
        while days.count < totalDays {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Month header
            MonthHeaderView(monthDate: monthDate)
            
            // Days of week header
            WeekdayHeaderView(configuration: viewModel.configuration)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { index, date in
                    MonthDayCell(
                        date: date,
                        selectedDate: viewModel.selectedDate,
                        viewModel: viewModel,
                        onDateTapped: { tappedDate in
                            viewModel.selectDate(tappedDate)
                            viewModel.toggleMonthView() // Close month view after selection
                        }
                    )
                    .frame(height: (geometry.size.height - 80) / 6) // 80 for header space
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Month Header View
struct MonthHeaderView: View {
    let monthDate: Date
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text(formatter.string(from: monthDate))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Weekday Header View
struct WeekdayHeaderView: View {
    let configuration: CalendarConfiguration
    
    private var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        let weekdaySymbols = formatter.shortWeekdaySymbols!
        
        if configuration.weekStartsOnMonday {
            // Rearrange to start with Monday
            return Array(weekdaySymbols[1...]) + [weekdaySymbols[0]]
        } else {
            return weekdaySymbols
        }
    }
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Month Day Cell
struct MonthDayCell: View {
    let date: Date?
    let selectedDate: Date
    @ObservedObject var viewModel: CalendarViewModel
    let onDateTapped: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Group {
            if let date = date {
                Button(action: {
                    onDateTapped(date)
                }) {
                    ZStack {
                        // Selection background
                        if calendar.isDate(date, inSameDayAs: selectedDate) {
                            Circle()
                                .fill(Color.accentColor)
                                .scaleEffect(0.8)
                        }
                        
                        VStack(spacing: 2) {
                            // Day number
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(dayTextColor(for: date))
                            
                            // Event indicators
                            EventIndicatorsView(
                                events: viewModel.eventsForDay(date),
                                maxIndicators: 3
                            )
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Empty cell
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func dayTextColor(for date: Date) -> Color {
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return .white
        } else if calendar.isDate(date, inSameDayAs: Date()) {
            return .accentColor
        } else {
            return .primary
        }
    }
}

// MARK: - Event Indicators View
struct EventIndicatorsView: View {
    let events: [Event]
    let maxIndicators: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(events.prefix(maxIndicators), id: \.id) { event in
                Circle()
                    .fill(Color(event.color))
                    .frame(width: 4, height: 4)
            }
            
            if events.count > maxIndicators {
                Text("+\(events.count - maxIndicators)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 8)
    }
}
import SwiftUI
import UIKit

// MARK: - Day View SwiftUI Component
struct DayView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var zoomScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemBackground)
                
                // Day content with pinch-to-zoom
                DayContentView(
                    viewModel: viewModel,
                    geometry: geometry,
                    zoomScale: $zoomScale
                )
                .scaleEffect(zoomScale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = value
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                // Apply zoom to hour height and reset scale
                                viewModel.updateZoom(value)
                                zoomScale = 1.0
                            }
                        }
                )
                
                // Today indicator line
                if viewModel.isSelectedDateToday {
                    CurrentTimeIndicator(
                        viewModel: viewModel,
                        geometry: geometry
                    )
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Horizontal swipe to change days
                    let threshold: CGFloat = 50
                    if value.translation.x > threshold {
                        viewModel.moveToPreviousDay()
                    } else if value.translation.x < -threshold {
                        viewModel.moveToNextDay()
                    }
                }
        )
    }
}

// MARK: - Day Content View
struct DayContentView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let geometry: GeometryProxy
    @Binding var zoomScale: CGFloat
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HourRowView(
                        hour: hour,
                        viewModel: viewModel,
                        width: geometry.size.width
                    )
                    .frame(height: viewModel.hourHeight)
                }
            }
        }
        .onAppear {
            // Scroll to current hour if viewing today
            if viewModel.isSelectedDateToday {
                scrollToCurrentHour()
            }
        }
        .onChange(of: viewModel.selectedDate) { _ in
            if viewModel.isSelectedDateToday {
                scrollToCurrentHour()
            }
        }
    }
    
    private func scrollToCurrentHour() {
        // This would require a ScrollViewReader in the actual implementation
        // For now, this serves as a placeholder for the scroll-to-current-hour logic
    }
}

// MARK: - Hour Row View
struct HourRowView: View {
    let hour: Int
    @ObservedObject var viewModel: CalendarViewModel
    let width: CGFloat
    
    private var events: [Event] {
        viewModel.eventsForDay(viewModel.selectedDate)
            .filter { event in
                let calendar = Calendar.current
                let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: viewModel.selectedDate)!
                let hourEnd = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: viewModel.selectedDate)!
                
                return event.startDate < hourEnd && event.endDate > hourStart
            }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Time label
            VStack {
                Text(hourString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(width: 60)
            .padding(.top, 4)
            
            // Event area
            ZStack(alignment: .topLeading) {
                // Hour separator line
                VStack {
                    Divider()
                        .background(Color(.separator))
                    Spacer()
                }
                
                // Events for this hour
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    EventView(
                        event: event,
                        date: viewModel.selectedDate,
                        hourHeight: viewModel.hourHeight,
                        totalEvents: events.count,
                        eventIndex: index,
                        width: width - 60
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: viewModel.hourHeight)
    }
    
    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Event View
struct EventView: View {
    let event: Event
    let date: Date
    let hourHeight: CGFloat
    let totalEvents: Int
    let eventIndex: Int
    let width: CGFloat
    
    var body: some View {
        let eventLayout = calculateEventLayout()
        
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(event.color))
            .frame(
                width: eventLayout.width,
                height: eventLayout.height
            )
            .offset(
                x: eventLayout.offsetX,
                y: eventLayout.offsetY
            )
            .overlay(
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if eventLayout.height > 30 {
                        Text(eventTimeString)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            )
    }
    
    private func calculateEventLayout() -> (width: CGFloat, height: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        guard let portion = event.portionOn(date: date) else {
            return (width: 0, height: 0, offsetX: 0, offsetY: 0)
        }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Calculate vertical position and height
        let startMinutes = calendar.dateComponents([.minute], from: dayStart, to: portion.start).minute ?? 0
        let durationMinutes = calendar.dateComponents([.minute], from: portion.start, to: portion.end).minute ?? 0
        
        let offsetY = CGFloat(startMinutes) * (hourHeight / 60.0)
        let height = max(CGFloat(durationMinutes) * (hourHeight / 60.0), 20) // Minimum height
        
        // Calculate horizontal position and width (for overlapping events)
        let eventWidth = width / CGFloat(max(totalEvents, 1))
        let offsetX = eventWidth * CGFloat(eventIndex)
        
        return (width: eventWidth - 2, height: height, offsetX: offsetX, offsetY: offsetY)
    }
    
    private var eventTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

// MARK: - Current Time Indicator
struct CurrentTimeIndicator: View {
    @ObservedObject var viewModel: CalendarViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        let position = calculateCurrentTimePosition()
        
        HStack(spacing: 0) {
            // Time indicator circle
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .padding(.leading, 56) // Align with hour labels
            
            // Time indicator line
            Rectangle()
                .fill(Color.red)
                .frame(height: 1)
        }
        .offset(y: position.y)
        .opacity(position.isVisible ? 1 : 0)
    }
    
    private func calculateCurrentTimePosition() -> (y: CGFloat, isVisible: Bool) {
        let calendar = Calendar.current
        let now = viewModel.currentTime
        
        guard calendar.isDate(now, inSameDayAs: viewModel.selectedDate) else {
            return (y: 0, isVisible: false)
        }
        
        let startOfDay = calendar.startOfDay(for: now)
        let minutesFromStart = calendar.dateComponents([.minute], from: startOfDay, to: now).minute ?? 0
        
        let yPosition = CGFloat(minutesFromStart) * (viewModel.hourHeight / 60.0) - geometry.size.height / 2
        
        return (y: yPosition, isVisible: true)
    }
}
import SwiftUI

// MARK: - Main Calendar View
struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    
    init(events: [Event] = [], configuration: CalendarConfiguration = .default) {
        self._viewModel = StateObject(wrappedValue: CalendarViewModel(events: events, configuration: configuration))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Week bar at the top
                WeekBarView(viewModel: viewModel) {
                    viewModel.toggleMonthView()
                }
                .frame(height: 80)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // Main content area
                ZStack {
                    // Day view (always present)
                    DayView(viewModel: viewModel)
                        .opacity(viewModel.isMonthViewExpanded ? 0 : 1)
                        .scaleEffect(viewModel.isMonthViewExpanded ? 0.95 : 1)
                    
                    // Month view (overlay when expanded)
                    if viewModel.isMonthViewExpanded {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.toggleMonthView()
                            }
                        
                        VStack {
                            Spacer(minLength: 20)
                            
                            MonthView(viewModel: viewModel)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 20)
                                )
                                .padding()
                            
                            Spacer(minLength: 40)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isMonthViewExpanded)
    }
}

// MARK: - Calendar View with Binding Support
struct CalendarViewWithBinding: View {
    @StateObject private var viewModel: CalendarViewModel
    @Binding var selectedDate: Date
    
    init(
        selectedDate: Binding<Date>,
        events: [Event] = [],
        configuration: CalendarConfiguration = .default
    ) {
        self._selectedDate = selectedDate
        self._viewModel = StateObject(wrappedValue: CalendarViewModel(events: events, configuration: configuration))
    }
    
    var body: some View {
        CalendarView(events: [], configuration: viewModel.configuration)
            .onReceive(viewModel.$selectedDate) { newDate in
                if selectedDate != newDate {
                    selectedDate = newDate
                }
            }
            .onReceive($selectedDate.publisher) { newDate in
                if viewModel.selectedDate != newDate {
                    viewModel.selectDate(newDate)
                }
            }
            .onAppear {
                viewModel.selectDate(selectedDate)
            }
    }
}

// MARK: - Preview Support
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(events: sampleEvents)
    }
    
    static var sampleEvents: [Event] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            Event(
                startDate: calendar.date(byAdding: .hour, value: 9, to: calendar.startOfDay(for: today))!,
                endDate: calendar.date(byAdding: .hour, value: 10, to: calendar.startOfDay(for: today))!,
                title: "Team Meeting",
                color: .systemBlue
            ),
            Event(
                startDate: calendar.date(byAdding: .hour, value: 14, to: calendar.startOfDay(for: today))!,
                endDate: calendar.date(byAdding: .hour, value: 15, to: calendar.startOfDay(for: today))!,
                title: "Client Call",
                color: .systemGreen
            ),
            Event(
                startDate: calendar.date(byAdding: .hour, value: 16, to: calendar.startOfDay(for: today))!,
                endDate: calendar.date(byAdding: .hour, value: 17, to: calendar.startOfDay(for: today))!,
                title: "Code Review",
                color: .systemOrange
            )
        ]
    }
}
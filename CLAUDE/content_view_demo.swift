import SwiftUI

// MARK: - Demo Content View
struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var events: [Event] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Calendar View
                CalendarViewWithBinding(
                    selectedDate: $selectedDate,
                    events: events,
                    configuration: .default
                )
                
                // Demo controls
                VStack(spacing: 16) {
                    Divider()
                    
                    HStack {
                        Text("Selected: \(formattedDate)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Today") {
                            selectedDate = Date()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    Button("Add Sample Event") {
                        addSampleEvent()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Calendar Demo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSampleEvents()
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private func loadSampleEvents() {
        let calendar = Calendar.current
        let today = Date()
        
        events = [
            // Today's events
            Event(
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: today)!,
                title: "Team Standup",
                color: .systemBlue
            ),
            Event(
                startDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
                title: "Product Review",
                color: .systemGreen
            ),
            Event(
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!,
                title: "Client Presentation",
                color: .systemRed
            ),
            Event(
                startDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)!,
                title: "Code Review",
                color: .systemOrange
            ),
            
            // Tomorrow's events
            Event(
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                title: "Design Workshop",
                color: .systemPurple
            ),
            Event(
                startDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                endDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                title: "Sprint Planning",
                color: .systemTeal
            ),
            
            // Yesterday's events
            Event(
                startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: today)!)!,
                endDate: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: -1, to: today)!)!,
                title: "Retrospective",
                color: .systemIndigo
            )
        ]
    }
    
    private func addSampleEvent() {
        let calendar = Calendar.current
        let randomHour = Int.random(in: 8...17)
        let duration = Int.random(in: 30...120) // 30-120 minutes
        
        let startDate = calendar.date(bySettingHour: randomHour, minute: 0, second: 0, of: selectedDate)!
        let endDate = calendar.date(byAdding: .minute, value: duration, to: startDate)!
        
        let titles = [
            "New Meeting", "Workshop", "Call", "Review Session",
            "Training", "Brainstorm", "Demo", "Planning"
        ]
        
        let colors: [UIColor] = [
            .systemBlue, .systemGreen, .systemRed, .systemOrange,
            .systemPurple, .systemTeal, .systemIndigo, .systemPink
        ]
        
        let newEvent = Event(
            startDate: startDate,
            endDate: endDate,
            title: titles.randomElement() ?? "Event",
            color: colors.randomElement() ?? .systemBlue
        )
        
        events.append(newEvent)
    }
}

// MARK: - App Entry Point
@main
struct CalendarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
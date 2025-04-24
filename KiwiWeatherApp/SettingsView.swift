import SwiftUI

struct SettingsView: View {
    @Binding var isCelsius: Bool
    @State private var notificationsEnabled = false
    @State private var dailyForecastEnabled = false
    @State private var weatherAlertsEnabled = false
    @State private var selectedTime = Date()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.3),
                        Color(red: 0.1, green: 0.6, blue: 0.4).opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Form {
                        Section(header: Text("Temperature Unit")) {
                            Toggle(isOn: $isCelsius) {
                                HStack {
                                    Image(systemName: "thermometer")
                                        .foregroundColor(.green)
                                    Text(isCelsius ? "Celsius (°C)" : "Fahrenheit (°F)")
                                }
                            }
                            .tint(.green)
                        }
                        
                        Section(header: Text("Notifications")) {
                            Toggle(isOn: $notificationsEnabled) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.green)
                                    Text("Enable Notifications")
                                }
                            }
                            .tint(.green)
                            .onChange(of: notificationsEnabled) { enabled in
                                if enabled {
                                    NotificationManager.shared.requestPermission()
                                }
                            }
                            
                            if notificationsEnabled {
                                Toggle(isOn: $dailyForecastEnabled) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.green)
                                        Text("Daily Forecast")
                                    }
                                }
                                .tint(.green)
                                .onChange(of: dailyForecastEnabled) { enabled in
                                    if enabled {
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                                        NotificationManager.shared.scheduleWeatherNotification(
                                            title: "Kiwi Weather Daily Forecast",
                                            body: "Here's your weather forecast for today!",
                                            hour: components.hour ?? 8,
                                            minute: components.minute ?? 0
                                        )
                                    }
                                }
                                
                                if dailyForecastEnabled {
                                    DatePicker("Notification Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                }
                                
                                Toggle(isOn: $weatherAlertsEnabled) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.green)
                                        Text("Weather Alerts")
                                    }
                                }
                                .tint(.green)
                            }
                        }
                        
                        Section(header: Text("About")) {
                            HStack {
                                Image("kiwi-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                Text("Kiwi Weather")
                                Spacer()
                                Text("Version 1.0")
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.green)
                                Text("Weather data provided by OpenWeatherMap")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

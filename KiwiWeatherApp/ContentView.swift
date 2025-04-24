import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var isCelsius = true
    @State private var showingSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    // Enhanced color scheme
    let lightGradient = Gradient(colors: [
        Color(red: 0.4, green: 0.8, blue: 0.4),
        Color(red: 0.1, green: 0.6, blue: 0.4)
    ])
    
    let darkGradient = Gradient(colors: [
        Color(red: 0.1, green: 0.3, blue: 0.2),
        Color(red: 0.05, green: 0.2, blue: 0.1)
    ])
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background gradient
                LinearGradient(
                    gradient: colorScheme == .dark ? darkGradient : lightGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Decorative circles in background
                GeometryReader { geometry in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: geometry.size.width * 0.7)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: geometry.size.width * 0.5)
                        .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.7)
                }
                
                VStack(spacing: 0) {
                    // Enhanced header with logo, app title and buttons
                    HStack {
                        // Logo and title
                        HStack(spacing: 8) {
                            Image("kiwi-logo")  // Use your logo image name here
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            
                            Text("Kiwi Weather")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                        // Temperature unit toggle
                        Button(action: {
                            isCelsius.toggle()
                        }) {
                            Text(isCelsius ? "°C" : "°F")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        
                        // Settings button
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Enhanced search bar with location button
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Search for a city", text: $searchText)
                                .foregroundColor(.white)
                                .accentColor(.white)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .onSubmit {
                                    if !searchText.isEmpty {
                                        withAnimation {
                                            weatherViewModel.fetchWeather(for: searchText)
                                        }
                                    }
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(15)
                        
                        Button(action: {
                            withAnimation {
                                locationManager.requestLocation()
                            }
                        }) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Main content
                    ZStack {
                        if weatherViewModel.isLoading || locationManager.isLoading {
                            LoadingView()
                        } else if let weather = weatherViewModel.weather {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 24) {
                                    // Enhanced current weather view
                                    EnhancedWeatherView(weather: weather, isCelsius: isCelsius)
                                    
                                    // Weather map
                                    if let location = locationManager.location {
                                        WeatherMapView(
                                            latitude: location.coordinate.latitude,
                                            longitude: location.coordinate.longitude
                                        )
                                    } else {
                                        WeatherMapView(
                                            latitude: 0, // Default or placeholder
                                            longitude: 0
                                        )
                                    }
                                    
                                    // Enhanced forecast section
                                    if !weatherViewModel.forecast.isEmpty {
                                        EnhancedForecastView(forecast: weatherViewModel.forecast, isCelsius: isCelsius)
                                    }
                                    
                                    // Weather details section
                                    WeatherDetailsView(weather: weather, isCelsius: isCelsius)
                                    
                                    // App info
                                    VStack(spacing: 8) {
                                        Text("Kiwi Weather App")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Text("Data provided by OpenWeatherMap")
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.top, 16)
                                    .padding(.bottom, 32)
                                }
                                .padding(.top, 16)
                            }
                        } else if let errorMessage = weatherViewModel.errorMessage {
                            ErrorView(message: errorMessage)
                        } else if let locationError = locationManager.errorMessage {
                            ErrorView(message: locationError)
                        } else {
                            WelcomeView()
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.top, getSafeAreaTop())
                .padding(.bottom, getSafeAreaBottom())
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isCelsius: $isCelsius)
            }
        }
        .onChange(of: locationManager.location) { location in
            if let location = location {
                weatherViewModel.fetchWeatherForLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
    
    // Fixed safe area functions
    func getSafeAreaTop() -> CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets.top ?? 0
    }
    
    func getSafeAreaBottom() -> CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Enhanced Weather View
struct EnhancedWeatherView: View {
    let weather: Weather
    let isCelsius: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Location name with animation
            Text(weather.location)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -10)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Weather icon and condition
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 140)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    enhancedWeatherIcon(for: weather.condition)
                        .font(.system(size: 60))
                        .scaleEffect(isAnimating ? 1 : 0.7)
                    
                    Text(weather.condition)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                }
            }
            .padding(.vertical, 8)
            
            // Temperature with animation
            Text(convertTemperature(weather.temperature))
                .font(.system(size: 90, weight: .thin, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                .scaleEffect(isAnimating ? 1 : 0.8)
            
            // Date and time
            Text(formattedDate())
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, -10)
                .opacity(isAnimating ? 1 : 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
    
    func convertTemperature(_ celsius: Double) -> String {
        if isCelsius {
            return "\(Int(celsius))°C"
        } else {
            let fahrenheit = celsius * 9/5 + 32
            return "\(Int(fahrenheit))°F"
        }
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d • h:mm a"
        return formatter.string(from: Date())
    }
    
    @ViewBuilder
    func enhancedWeatherIcon(for condition: String) -> some View {
        switch condition.lowercased() {
        case let s where s.contains("clear"):
            Image(systemName: "sun.max.fill")
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 0)
        case let s where s.contains("cloud"):
            Image(systemName: "cloud.fill")
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 0)
        case let s where s.contains("rain"):
            Image(systemName: "cloud.rain.fill")
                .foregroundColor(.blue)
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 0)
        case let s where s.contains("snow"):
            Image(systemName: "snow")
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 0)
        case let s where s.contains("thunder"):
            Image(systemName: "cloud.bolt.fill")
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 5, x: 0, y: 0)
        case let s where s.contains("mist") || s.contains("fog"):
            Image(systemName: "cloud.fog.fill")
                .foregroundColor(.gray)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 0)
        default:
            Image(systemName: "cloud.fill")
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 0)
        }
    }
}

// MARK: - Enhanced Forecast View
struct EnhancedForecastView: View {
    let forecast: [ForecastDay]
    let isCelsius: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("5-Day Forecast")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.leading, 20)
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -20)
            
            VStack(spacing: 12) {
                ForEach(Array(forecast.enumerated()), id: \.element.date) { index, day in
                    EnhancedForecastDayView(forecast: day, isCelsius: isCelsius)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(Animation.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: isAnimating)
                }
            }
            .padding(.vertical, 10)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                isAnimating = true
            }
        }
    }
}

struct EnhancedForecastDayView: View {
    let forecast: ForecastDay
    let isCelsius: Bool
    
    var body: some View {
        HStack {
            Text(dayOfWeek(from: forecast.date))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            enhancedWeatherIcon(for: forecast.condition)
                .font(.system(size: 22))
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(convertTemperature(forecast.maxTemperature))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(convertTemperature(forecast.minTemperature))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 100)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.08))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    func convertTemperature(_ celsius: Double) -> String {
        if isCelsius {
            return "\(Int(celsius))°"
        } else {
            let fahrenheit = celsius * 9/5 + 32
            return "\(Int(fahrenheit))°"
        }
    }
    
    func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    func enhancedWeatherIcon(for condition: String) -> some View {
        switch condition.lowercased() {
        case let s where s.contains("clear"):
            Image(systemName: "sun.max.fill")
                .foregroundColor(.yellow)
        case let s where s.contains("cloud"):
            Image(systemName: "cloud.fill")
                .foregroundColor(.white)
        case let s where s.contains("rain"):
            Image(systemName: "cloud.rain.fill")
                .foregroundColor(.blue)
        case let s where s.contains("snow"):
            Image(systemName: "snow")
                .foregroundColor(.white)
        case let s where s.contains("thunder"):
            Image(systemName: "cloud.bolt.fill")
                .foregroundColor(.yellow)
        default:
            Image(systemName: "cloud.fill")
                .foregroundColor(.white)
        }
    }
}

// MARK: - Weather Details View
struct WeatherDetailsView: View {
    let weather: Weather
    let isCelsius: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weather Details")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.leading, 20)
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                EnhancedDetailCard(
                    title: "Feels Like",
                    value: convertTemperature(weather.feelsLike),
                    icon: "thermometer",
                    delay: 0.1
                )
                
                EnhancedDetailCard(
                    title: "Humidity",
                    value: "\(weather.humidity)%",
                    icon: "humidity.fill",
                    delay: 0.2
                )
                
                EnhancedDetailCard(
                    title: "Wind Speed",
                    value: "\(Int(weather.windSpeed)) km/h",
                    icon: "wind",
                    delay: 0.3
                )
                
                EnhancedDetailCard(
                    title: "Pressure",
                    value: "\(weather.pressure) hPa",
                    icon: "gauge",
                    delay: 0.4
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6)) {
                isAnimating = true
            }
        }
    }
    
    func convertTemperature(_ celsius: Double) -> String {
        if isCelsius {
            return "\(Int(celsius))°C"
        } else {
            let fahrenheit = celsius * 9/5 + 32
            return "\(Int(fahrenheit))°F"
        }
    }
}

struct EnhancedDetailCard: View {
    let title: String
    let value: String
    let icon: String
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            Text("Loading weather data...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.5)
            
            Text("Oops!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -20)
            
            Text(message)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Your logo
            Image("kiwi-logo")  // Use your logo image name here
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.5)
            
            Text("Welcome to Kiwi Weather")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -20)
            
            Text("Search for a city or use your current location to get the latest weather information")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            // Animated clouds
            ZStack {
                ForEach(0..<3) { index in
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 30 + CGFloat(index * 10)))
                        .foregroundColor(.white.opacity(0.3 - Double(index) * 0.05))
                        .offset(x: isAnimating ? CGFloat((-1 + index) * 80) : CGFloat((-1 + index) * 40), y: CGFloat(index * 15))
                        .animation(
                            Animation.easeInOut(duration: 4 + Double(index))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index)),
                            value: isAnimating
                        )
                }
            }
            .padding(.top, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

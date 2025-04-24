import Foundation
import CoreLocation

struct Weather {
    let location: String
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let pressure: Int
    let windSpeed: Double
    let condition: String
}

struct ForecastDay {
    let date: Date
    let temperature: Double
    let minTemperature: Double
    let maxTemperature: Double
    let condition: String
    let icon: String
}

class WeatherViewModel: ObservableObject {
    @Published var weather: Weather?
    @Published var forecast: [ForecastDay] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Using the provided API key
    private let apiKey = "<PUT-YOUR-API-KEY"
    
    func fetchWeather(for city: String) {
        guard !city.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        weather = nil
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            isLoading = false
            errorMessage = "Invalid city name"
            return
        }
        
        print("Fetching weather from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let cod = json["cod"] as? String, cod != "200" {
                            let message = json["message"] as? String ?? "City not found"
                            self?.errorMessage = "Error: \(message)"
                            return
                        }
                        
                        if let main = json["main"] as? [String: Any],
                           let wind = json["wind"] as? [String: Any],
                           let weather = (json["weather"] as? [[String: Any]])?.first {
                            
                            let location = json["name"] as? String ?? "Unknown"
                            let temperature = main["temp"] as? Double ?? 0.0
                            let feelsLike = main["feels_like"] as? Double ?? 0.0
                            let humidity = main["humidity"] as? Int ?? 0
                            let pressure = main["pressure"] as? Int ?? 0
                            let windSpeed = wind["speed"] as? Double ?? 0.0
                            let condition = weather["main"] as? String ?? "Unknown"
                            
                            self?.weather = Weather(
                                location: location,
                                temperature: temperature,
                                feelsLike: feelsLike,
                                humidity: humidity,
                                pressure: pressure,
                                windSpeed: windSpeed,
                                condition: condition
                            )
                            
                            // After getting current weather, fetch the forecast
                            self?.fetchForecast(for: city)
                            
                            // Schedule a weather alert if needed
                            if let condition = self?.weather?.condition, let temp = self?.weather?.temperature {
                                if condition.lowercased().contains("rain") ||
                                   condition.lowercased().contains("snow") ||
                                   temp > 30 || temp < 0 {
                                    NotificationManager.shared.scheduleWeatherAlert(
                                        for: condition,
                                        temperature: temp,
                                        in: 1
                                    )
                                }
                            }
                        } else {
                            self?.errorMessage = "Could not parse weather data"
                        }
                    } else {
                        self?.errorMessage = "Invalid response format"
                    }
                } catch {
                    self?.errorMessage = "Error parsing data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchForecast(for city: String) {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(city)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            return
        }
        
        print("Fetching forecast from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Forecast error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No forecast data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let list = json["list"] as? [[String: Any]] {
                        
                        var forecastDays: [ForecastDay] = []
                        var processedDates = Set<String>()
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        for item in list {
                            if let dt = item["dt"] as? TimeInterval,
                               let main = item["main"] as? [String: Any],
                               let weather = (item["weather"] as? [[String: Any]])?.first {
                                
                                let date = Date(timeIntervalSince1970: dt)
                                let dateString = dateFormatter.string(from: date)
                                
                                // Only take one forecast per day
                                if !processedDates.contains(dateString) {
                                    processedDates.insert(dateString)
                                    
                                    let temp = main["temp"] as? Double ?? 0.0
                                    let minTemp = main["temp_min"] as? Double ?? 0.0
                                    let maxTemp = main["temp_max"] as? Double ?? 0.0
                                    let condition = weather["main"] as? String ?? "Unknown"
                                    let icon = weather["icon"] as? String ?? "01d"
                                    
                                    let forecastDay = ForecastDay(
                                        date: date,
                                        temperature: temp,
                                        minTemperature: minTemp,
                                        maxTemperature: maxTemp,
                                        condition: condition,
                                        icon: icon
                                    )
                                    
                                    forecastDays.append(forecastDay)
                                    
                                    // Limit to 5 days
                                    if forecastDays.count >= 5 {
                                        break
                                    }
                                }
                            }
                        }
                        
                        self?.forecast = forecastDays
                    }
                } catch {
                    print("Error parsing forecast data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func fetchWeatherForLocation(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        weather = nil
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Invalid location"
            return
        }
        
        print("Fetching weather for location: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let cod = json["cod"] as? String, cod != "200" {
                            let message = json["message"] as? String ?? "Location not found"
                            self?.errorMessage = "Error: \(message)"
                            return
                        }
                        
                        if let main = json["main"] as? [String: Any],
                           let wind = json["wind"] as? [String: Any],
                           let weather = (json["weather"] as? [[String: Any]])?.first {
                            
                            let location = json["name"] as? String ?? "Current Location"
                            let temperature = main["temp"] as? Double ?? 0.0
                            let feelsLike = main["feels_like"] as? Double ?? 0.0
                            let humidity = main["humidity"] as? Int ?? 0
                            let pressure = main["pressure"] as? Int ?? 0
                            let windSpeed = wind["speed"] as? Double ?? 0.0
                            let condition = weather["main"] as? String ?? "Unknown"
                            
                            self?.weather = Weather(
                                location: location,
                                temperature: temperature,
                                feelsLike: feelsLike,
                                humidity: humidity,
                                pressure: pressure,
                                windSpeed: windSpeed,
                                condition: condition
                            )
                            
                            // After getting current weather, fetch the forecast for this location
                            self?.fetchForecastForLocation(latitude: latitude, longitude: longitude)
                        } else {
                            self?.errorMessage = "Could not parse weather data"
                        }
                    } else {
                        self?.errorMessage = "Invalid response format"
                    }
                } catch {
                    self?.errorMessage = "Error parsing data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func fetchForecastForLocation(latitude: Double, longitude: Double) {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            return
        }
        
        print("Fetching forecast for location: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Forecast error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No forecast data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let list = json["list"] as? [[String: Any]] {
                        
                        var forecastDays: [ForecastDay] = []
                        var processedDates = Set<String>()
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        for item in list {
                            if let dt = item["dt"] as? TimeInterval,
                               let main = item["main"] as? [String: Any],
                               let weather = (item["weather"] as? [[String: Any]])?.first {
                                
                                let date = Date(timeIntervalSince1970: dt)
                                let dateString = dateFormatter.string(from: date)
                                
                                // Only take one forecast per day
                                if !processedDates.contains(dateString) {
                                    processedDates.insert(dateString)
                                    
                                    let temp = main["temp"] as? Double ?? 0.0
                                    let minTemp = main["temp_min"] as? Double ?? 0.0
                                    let maxTemp = main["temp_max"] as? Double ?? 0.0
                                    let condition = weather["main"] as? String ?? "Unknown"
                                    let icon = weather["icon"] as? String ?? "01d"
                                    
                                    let forecastDay = ForecastDay(
                                        date: date,
                                        temperature: temp,
                                        minTemperature: minTemp,
                                        maxTemperature: maxTemp,
                                        condition: condition,
                                        icon: icon
                                    )
                                    
                                    forecastDays.append(forecastDay)
                                    
                                    // Limit to 5 days
                                    if forecastDays.count >= 5 {
                                        break
                                    }
                                }
                            }
                        }
                        
                        self?.forecast = forecastDays
                    }
                } catch {
                    print("Error parsing forecast data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

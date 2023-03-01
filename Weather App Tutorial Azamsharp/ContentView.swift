//
//  ContentView.swift
//  Weather App Tutorial Azamsharp
//
//  Created by Brayton Lordianto on 1/31/23.
//

import SwiftUI
import CoreLocation
import WeatherKit
import Charts

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var currentLocation: CLLocation?
    private let locationManager = CLLocationManager() // much like cmmotionmanager or whatever
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        // ask for the user's location always
        locationManager.requestAlwaysAuthorization()
        // start updating location -- standard proc for these manager objects
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
}

extension LocationManager {
    // tells the delegate that there is a new location data available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, currentLocation == nil else { return }
        
        // actually this means to run it in the main thread
        // which is concurrently but not on background
        // this is so that the UI changes of current location will only be done in main thread
        // sometimes running on main not good since u have to wait for other in queue
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
}

struct HourlyForecastView: View {
    // a structure that represents the weather conditions for a given hour
    // 18.00 on finishing of the hourWeahter list
    // basically includes all the predictions for the next hours etc.
    let hourWeatherList: [HourWeather]
    var body: some View {
        VStack(alignment: .leading) {
            Text("HOURLY FORECAST")
                .font(.caption)
                .opacity(0.5)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(hourWeatherList,  id: \.date) { hourWeather in
                        VStack(spacing: 20) {
                            // Text(hourWeather.date.formatted(date: .omitted, time: .shortened)) // 12:00 etc
                            Text(hourWeather.date.formatAsAbbreviatedTime()) // 12AM etc
                            
                            // shows the hour weather condition -- ex. sunny, clooudy etc
                            Image(systemName: "\(hourWeather.symbolName).fill")
                                .foregroundColor(.yellow)
                            Text(hourWeather.temperature.formatted())
                                .fontWeight(.medium)
                        }.padding()
                    }
                }
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                .foregroundColor(.white)
                
            }
        }
    }
}

// instead of just the date, I wnat it to show as like Mon or Tue etc
extension Date {
    func formatAsAbbreviatedDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    func formatAsAbbreviatedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: self)
    }
}

struct TenDayForecastView: View {
    // you get weather for the next ten days
    let dayWeatherList: [DayWeather]
    
    var body: some View {
        VStack {
            // 26.27 - finsihing ten forecast view.
            Text("10 Day Forecast")
                .font(.caption)
                .opacity(0.5)
            
            List(dayWeatherList, id: \.date) { dailyWeather in
                HStack {
                    Text(dailyWeather.date.formatAsAbbreviatedDay()) // MON TUE ...
                        .frame(maxWidth: 50, alignment:.leading)
                    
                    Image(systemName: "\(dailyWeather.symbolName)")
                        .foregroundColor(.yellow)
                    
                    Text(dailyWeather.lowTemperature.formatted())
                        .frame(maxWidth: .infinity)
                    
                    Text(dailyWeather.highTemperature.formatted())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .listRowBackground(Color.red)
            }
            .listStyle(.plain)
        }
        .background {
            Color.blue
        }
        .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
        .foregroundColor(.white)
    }
}

struct hourlyForecastChartView: View {
    var hourlyWeatherData: [HourWeather]
    
    var body: some View {
        Chart {
            ForEach(hourlyWeatherData.prefix(10), id: \.date) { hourlyWeather in
                // MARK: can use point mark, line mark, bar mark, etc
                BarMark(x: .value("Hour", hourlyWeather.date.formatAsAbbreviatedTime()),
                         y: .value("Temperature", hourlyWeather.temperature.value))
            }
        }
    }
}

struct ContentView: View {
    // we need the location manager and the weather fetcher
    // api wrapper to get weather
    // shared so that all code accessing the same wrapper
    // which improves performance, reduce memory, and ensure consistency
    // basically like the filemanager i made but better?
    let weatherService = WeatherService.shared
    
    // Since instantiation will initialize loc manager, user will be asked for loc here
    @StateObject private var locationManager = LocationManager()
    
    // the weather object
    @State private var weather: Weather?
    
    // filter out the hourly weather from all times to just the next 24 hours
    // 23.52 -- ask gpt or sth 
    var hourlyWeatherData: [HourWeather] {
        return Array(weather?.hourlyForecast.forecast.filter({ hourWeather in
            hourWeather.date.timeIntervalSince(Date()) >= 0
        }).prefix(24) ?? []) ?? []
    }
    
    var body: some View {
        VStack {
            // new syntax to show if weather is not null
            if let weather {
                VStack {
                    Text("New York")
                        .font(.largeTitle)
                    Text("\(weather.currentWeather.temperature.formatted())")
                    
                    // weather.hourlyForecast.forecast gives everything from a lot
                    // HourlyForecastView(hourWeatherList: weather.hourlyForecast.forecast)
                    HourlyForecastView(hourWeatherList: hourlyWeatherData)
                    
                    // chart
                    hourlyForecastChartView(hourlyWeatherData: hourlyWeatherData)
                    
                    // [DayForecast]
                    TenDayForecastView(dayWeatherList: weather.dailyForecast.forecast)
                }
                
            }
            
            Spacer()
        }
        .padding()
        // want to get the weather as soon as the app is open, asynchronously.
        // gets done asynchronously whenever current location changes!
        // so it might be wasteful to keep on calling on the slightest location change -- I could make it only once, since you're not going to be changing location typically.
        .task(id: locationManager.currentLocation) {
            print(locationManager.currentLocation)
            if let location = locationManager.currentLocation {
                // func weather(for:CLLocation) async throws -> Weather
                weather = try? await weatherService.weather(for: location)
                print(weather)
            }
        }
        // 21.53
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

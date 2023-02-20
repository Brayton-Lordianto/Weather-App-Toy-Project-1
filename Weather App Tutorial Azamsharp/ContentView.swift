//
//  ContentView.swift
//  Weather App Tutorial Azamsharp
//
//  Created by Brayton Lordianto on 1/31/23.
//

import SwiftUI
import CoreLocation
import WeatherKit

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
                            Text(hourWeather.date.formatted(date: .omitted, time: .shortened))
                            
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

struct TenDayForecastView: View {
    let dayWeatherList: [DayWeather]
    
    var body: some View {
        VStack {
            // 26.27 - finsihing ten forecast view.
            Text("10 Day Forecast")
            
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

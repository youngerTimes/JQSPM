//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/11/17.
//

import Foundation
import WeatherKit
import CoreLocation
import UIKit

@available(iOS 16.0, *)
public struct WeatherServer:Sendable{

    public static func getWeather(_ location:CLLocationCoordinate2D)async ->(CurrentWeather,Forecast<DayWeather>)? {

        var weather:(CurrentWeather,Forecast<DayWeather>)?
        do{
            let weatherService = WeatherService.shared
            try await debugPrint(weatherService.attribution)
            let local = CLLocation(latitude: location.latitude, longitude: location.longitude)
            weather = try await weatherService.weather(for: local, including: .current,.daily)
        }catch let error{
            debugPrint(error)
            debugPrint("---->")
        }
        
        return weather
    }
}



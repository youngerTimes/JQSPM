//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/11/25.
//

import Foundation

/**
 let calculator = OxygenCalculator()

 // 1. 单组参数计算（实际气压85000 Pa，海拔1500米）
 let currentPressure: Double = 85000  // 实际气压 (Pa)
 let currentAltitude: Double = 1500   // 实际海拔 (m)

 let singleResult = calculator.calculateAllParameters(
 currentAtmosphericPressure: currentPressure,
 altitude: currentAltitude
 )

 print("=== 单组参数计算结果 ===")
 print("当前气压：\(currentPressure.roundTo(decimalPlaces: 2)) Pa")
 print("海拔：\(currentAltitude) m")
 print("估算温度：\(singleResult.temperature?.roundTo(decimalPlaces: 2) ?? 0) K")
 print("氧气分压：\(singleResult.oxygenPartialPressure.roundTo(decimalPlaces: 2)) Pa")
 print("氧气质量浓度：\(singleResult.oxygenMassConcentration?.roundTo(decimalPlaces: 6) ?? 0) kg/m³")
 print("氧气体积百分比：\(singleResult.oxygenPercentage?.roundTo(decimalPlaces: 4) ?? 0) %vol")
 print("（理想状态下百分比应接近 20.95%）\n")

 */

/// 氧气浓度计算工具类（支持质量浓度转百分比，输入实际气压和海拔）
public class JQ_OxygenCalculator {
    // MARK: - 核心常量（理论固定值）
    /// 氧气体积分数（恒定值）
    private let oxygenVolumeFraction: Double = 0.2095
    /// 氧气摩尔质量 (kg/mol)
    private let oxygenMolarMass: Double = 0.032
    /// 通用气体常数 (J/(mol·K))
    private let universalGasConstant: Double = 8.31432
    /// 海平面标准温度 (K)
    private let standardSeaLevelTemperature: Double = 288.15
    /// 对流层温度递减率 (K/m) - 用于根据海拔估算当前温度
    private let temperatureLapseRate: Double = 0.0065
    /// 适用海拔范围（对流层：0~11000m）
    private let minAltitude: Double = 0
    private let maxAltitude: Double = 11000

    public init() {

    }

    // MARK: - 辅助方法：估算当前海拔温度
    private func estimateTemperature(at altitude: Double) -> Double? {
        guard altitude >= minAltitude, altitude <= maxAltitude else {
            debugPrint("警告：海拔需在 \(minAltitude)~\(maxAltitude) 米范围内")
            return nil
        }
        // 公式：T(h) = T0 - L×h（T0=海平面标准温度，L=温度递减率）
        return standardSeaLevelTemperature - (temperatureLapseRate * altitude)
    }

    // MARK: - 核心计算方法
    /// 计算氧气分压 (Pa)
    public func calculateOxygenPartialPressure(currentAtmosphericPressure: Double) -> Double {
        return currentAtmosphericPressure * oxygenVolumeFraction
    }

    /// 计算氧气质量浓度 (kg/m³)
    public func calculateOxygenMassConcentration(
        currentAtmosphericPressure: Double,
        altitude: Double
    ) -> Double? {
        guard let currentTemperature = estimateTemperature(at: altitude) else { return nil }
        let oxygenPartialPressure = calculateOxygenPartialPressure(currentAtmosphericPressure: currentAtmosphericPressure)
        // 公式：ρO2 = (PO2 × MO2) / (R × T)
        return (oxygenPartialPressure * oxygenMolarMass) / (universalGasConstant * currentTemperature)
    }

    /// 质量浓度 转 氧气体积百分比（%vol）
    /// - Parameters:
    ///   - oxygenMassConcentration: 氧气质量浓度 (kg/m³)
    ///   - currentAtmosphericPressure: 当前大气总压 (Pa)
    ///   - altitude: 海拔 (m)（用于估算温度）
    /// - Returns: 氧气体积百分比（%vol），参数无效返回 nil
    public func convertMassConcentrationToPercentage(
        oxygenMassConcentration: Double,
        currentAtmosphericPressure: Double,
        altitude: Double
    ) -> Double? {
        guard let currentTemperature = estimateTemperature(at: altitude) else { return nil }

        // 步骤1：通过质量浓度反向推导氧气分压（改写理想气体状态方程）
        // 推导公式：PO2 = (ρO2 × R × T) / MO2
        let oxygenPartialPressure = (oxygenMassConcentration * universalGasConstant * currentTemperature) / oxygenMolarMass

        // 步骤2：通过分压计算体积百分比（道尔顿分压定律）
        // 公式：氧气百分比（%vol）= (PO2 / 总压) × 100
        let oxygenPercentage = (oxygenPartialPressure / currentAtmosphericPressure) * 100

        return oxygenPercentage
    }

    /// 一站式计算：输入气压+海拔，直接获取所有参数（含百分比）
    public func calculateAllParameters(
        currentAtmosphericPressure: Double,
        altitude: Double
    ) -> (
        temperature: Double?,
        oxygenPartialPressure: Double,
        oxygenMassConcentration: Double?,
        oxygenPercentage: Double?
    ) {
        let temperature = estimateTemperature(at: altitude)
        let partialPressure = calculateOxygenPartialPressure(currentAtmosphericPressure: currentAtmosphericPressure)
        let massConcentration = calculateOxygenMassConcentration(currentAtmosphericPressure: currentAtmosphericPressure, altitude: altitude)
        let percentage = massConcentration.flatMap {
            convertMassConcentrationToPercentage(
                oxygenMassConcentration: $0,
                currentAtmosphericPressure: currentAtmosphericPressure,
                altitude: altitude
            )
        }
        return (temperature, partialPressure, massConcentration, percentage)
    }

    /// 批量计算（含百分比）
    public func batchCalculate(
        parameters: [(currentPressure: Double, altitude: Double)]
    ) -> [[String: Double?]] {
        return parameters.map { param in
            let result = calculateAllParameters(
                currentAtmosphericPressure: param.currentPressure,
                altitude: param.altitude
            )
            return [
                "当前气压(Pa)": param.currentPressure,
                "海拔(m)": param.altitude,
                "估算温度(K)": result.temperature,
                "氧气分压(Pa)": result.oxygenPartialPressure,
                "氧气质量浓度(kg/m³)": result.oxygenMassConcentration,
                "氧气体积百分比(%vol)": result.oxygenPercentage
            ]
        }
    }
}

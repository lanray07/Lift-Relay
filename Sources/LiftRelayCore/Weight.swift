import Foundation

public enum WeightConverter {
    public static func display(kilograms: Double, unit: WeightUnit) -> Double {
        switch unit { case .kilograms: kilograms; case .pounds: kilograms * 2.204_622_621_8 }
    }

    public static func kilograms(from value: Double, unit: WeightUnit) -> Double {
        switch unit { case .kilograms: value; case .pounds: value / 2.204_622_621_8 }
    }
}

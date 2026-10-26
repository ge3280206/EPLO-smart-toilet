import Foundation

/// 功能分类
enum FeatureCat: String, CaseIterable, Identifiable {
    case wash, dry, seat, flush, clean, smart, safety

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wash: return "Washing"
        case .dry: return "Drying"
        case .seat: return "Seat"
        case .flush: return "Flush"
        case .clean: return "Hygiene"
        case .smart: return "Smart"
        case .safety: return "Safety"
        }
    }
}

/// 控件类型
enum FeatureKind {
    case action   // 一键执行
    case toggle   // 开关
    case level    // 档位
    case info     // 硬件级，仅说明
}

/// 单个功能项
struct Feature: Identifiable {
    let id: String
    let name: String
    let sub: String
    let cat: FeatureCat
    let kind: FeatureKind
    let cmd: UInt8
    var value: Int
    let minValue: Int
    let maxValue: Int
    let labels: [String]
    let note: String

    var isOn: Bool { value > 0 }

    var levelText: String {
        if labels.isEmpty { return "\(value)" }
        let idx = max(0, min(labels.count - 1, value - minValue))
        return labels[idx]
    }

    var canControl: Bool { kind != .info }
}

/// 全部功能清单（与安卓版完全一致，共 52 项）
enum FeatureRepo {

    static let tempLabels = ["Room", "Lv1", "Lv2", "Lv3", "Lv4", "Lv5"]
    static let p3Labels = ["Lv1", "Lv2", "Lv3"]
    static let p5Labels = ["Lv1", "Lv2", "Lv3", "Lv4", "Lv5"]
    static let lightLabels = ["Auto", "On", "Off"]
    static let userLabels = ["User 1", "User 2", "User 3", "User 4"]

    static func action(_ id: String, _ name: String, _ sub: String, _ cat: FeatureCat,
                       _ cmd: UInt8, _ note: String) -> Feature {
        Feature(id: id, name: name, sub: sub, cat: cat, kind: .action, cmd: cmd,
                value: 0, minValue: 0, maxValue: 0, labels: [], note: note)
    }

    static func toggle(_ id: String, _ name: String, _ sub: String, _ cat: FeatureCat,
                       _ cmd: UInt8, _ note: String) -> Feature {
        Feature(id: id, name: name, sub: sub, cat: cat, kind: .toggle, cmd: cmd,
                value: 0, minValue: 0, maxValue: 1, labels: [], note: note)
    }

    static func level(_ id: String, _ name: String, _ sub: String, _ cat: FeatureCat,
                      _ cmd: UInt8, _ minV: Int, _ maxV: Int, _ labels: [String],
                      _ def: Int, _ note: String) -> Feature {
        Feature(id: id, name: name, sub: sub, cat: cat, kind: .level, cmd: cmd,
                value: def, minValue: minV, maxValue: maxV, labels: labels, note: note)
    }

    static func info(_ id: String, _ name: String, _ sub: String, _ cat: FeatureCat,
                     _ note: String) -> Feature {
        Feature(id: id, name: name, sub: sub, cat: cat, kind: .info, cmd: 0,
                value: 0, minValue: 0, maxValue: 0, labels: [], note: note)
    }

    static func build() -> [Feature] {
        var list: [Feature] = []

        /* ---------------- WASHING ---------------- */
        list.append(action("rear_wash", "Rear Wash", "Cleansing", .wash, 0x01,
                           "Requires seating. Tap again to toggle oscillating wash."))
        list.append(action("front_wash", "Feminine Wash", "Cleansing", .wash, 0x02,
                           "Requires seating. Tap again to toggle oscillating wash."))
        list.append(toggle("oscillate", "Oscillating Wash", "Cleansing", .wash, 0x03,
                           "Nozzle moves back and forth while washing"))
        list.append(level("water_temp", "Water Temperature", "Cleansing", .wash, 0x04,
                          0, 5, tempLabels, 0, "0 = room temperature, levels 1-5 instant heating"))
        list.append(level("water_pressure", "Water Pressure", "Cleansing", .wash, 0x05,
                          1, 3, p3Labels, 2, "Water flow strength while washing"))
        list.append(level("nozzle_pos", "Nozzle Position", "Cleansing", .wash, 0x06,
                          1, 5, p5Labels, 3, "Nozzle forward/backward position while washing"))

        /* ---------------- DRYING ---------------- */
        list.append(action("dryer", "Warm Air Dry", "Drying", .dry, 0x10, "Requires seating"))
        list.append(level("dry_temp", "Dryer Temperature", "Drying", .dry, 0x11,
                          0, 5, tempLabels, 0, "0 = room temperature, levels 1-5"))
        list.append(level("fan_speed", "Air Speed", "Drying", .dry, 0x12,
                          1, 3, p3Labels, 2, "1 low / 2 medium / 3 high"))
        list.append(level("outlet_pos", "Outlet Position", "Drying", .dry, 0x13,
                          1, 5, p5Labels, 3, "Air outlet position while drying"))
        list.append(toggle("moving_dryer", "Moving Dryer", "Drying", .dry, 0x14,
                           "Air outlet oscillates while drying"))
        list.append(toggle("auto_dry", "Auto Dry after Wash", "Drying", .dry, 0x15,
                           "Warm air starts automatically after washing"))

        /* ---------------- SEAT ---------------- */
        list.append(level("seat_temp", "Heated Seat", "Seat", .seat, 0x20,
                          0, 5, tempLabels, 0, "0 = room temperature, levels 1-5, 50W heater"))
        list.append(toggle("seat_sensor", "Seat Sensor", "Seat", .seat, 0x21,
                           "Seat presence sensor starts wash / dry / deodorize"))
        list.append(info("soft_close", "Soft-close Lid", "Seat", .seat,
                         "Damped slow closing, no setting needed"))
        list.append(info("anti_scald_seat", "Anti-scald Seat", "Seat", .seat,
                         "Seat temperature steps down automatically after 10 min of continuous use"))

        /* ---------------- FLUSH ---------------- */
        list.append(action("flush_full", "Full Flush", "Flush", .flush, 0x40, "1.6 Gpf / 6.0 L"))
        list.append(action("flush_half", "Half Flush", "Flush", .flush, 0x41, "1.1 Gpf / 4.1 L"))
        list.append(toggle("auto_flush", "Auto Flush", "Flush", .flush, 0x42,
                           "Flushes automatically when you leave the seat"))
        list.append(toggle("foot_flush", "Foot-sensor Flush", "Flush", .flush, 0x43,
                           "Triggered by foot sensor (if equipped)"))
        list.append(action("men_flush", "Men's Flush", "Flush", .flush, 0x44,
                           "For standing use with seat opened"))
        list.append(action("emergency_flush", "Emergency Flush", "Flush", .flush, 0x45,
                           "Requires battery box, or pour about 8 L (2.1 Gal) of water into the bowl"))

        /* ---------------- HYGIENE ---------------- */
        list.append(action("nozzle_clean", "Nozzle Cleaning", "Hygiene", .clean, 0x50,
                           "Extends the nozzle when seat is unoccupied for manual cleaning"))
        list.append(toggle("uvc", "UVC Sterilization", "Hygiene", .clean, 0x51,
                           "UV dynamic water path sanitation"))
        list.append(toggle("plasma", "Plasma Sterilization", "Hygiene", .clean, 0x52,
                           "Plasma sterilization for seat area / nozzle"))
        list.append(toggle("foam", "Foam Shield", "Hygiene", .clean, 0x53,
                           "Anti-splash and odor barrier; auto foam off by default"))
        list.append(action("foam_manual", "Manual Foam", "Hygiene", .clean, 0x54,
                           "Foam once immediately"))
        list.append(toggle("deodorize", "Auto Deodorize", "Hygiene", .clean, 0x55,
                           "Starts when seated, stops when leaving or drying"))
        list.append(toggle("pre_wet", "Pre-wetting", "Hygiene", .clean, 0x56,
                           "Wets the bowl automatically when seated"))
        list.append(info("filter", "Filter Maintenance", "Hygiene", .clean,
                         "Clean the angle-valve filter when water flow becomes weak"))

        /* ---------------- LID · SMART ---------------- */
        list.append(action("lid_open", "Open Lid", "Lid & Smart", .smart, 0x30, "Open the lid"))
        list.append(action("lid_close", "Close Lid", "Lid & Smart", .smart, 0x31, "Close the lid"))
        list.append(action("seat_open", "Open Seat", "Lid & Smart", .smart, 0x32, "Open the seat"))
        list.append(action("seat_close", "Close Seat", "Lid & Smart", .smart, 0x33, "Close the seat"))
        list.append(toggle("auto_lid", "Auto Lid Opening", "Lid & Smart", .smart, 0x34,
                           "Microwave sensor opens/closes the lid (if equipped)"))
        list.append(toggle("foot_lid", "Foot-sensor Lid & Seat", "Lid & Smart", .smart, 0x35,
                           "Foot sensor toggles lid / seat / close both"))
        list.append(toggle("auto_lid_close", "Auto Close Lid", "Lid & Smart", .smart, 0x36,
                           "Closes the lid automatically when you leave"))
        list.append(level("night_light", "Night Light", "Comfort", .smart, 0x60,
                          0, 2, lightLabels, 0, "Auto sensing / always on / always off"))
        list.append(toggle("eco", "ECO Mode", "Comfort", .smart, 0x61,
                           "Seat temp drops to Lv1 automatically, pauses while seated"))
        list.append(toggle("quiet", "Quiet Mode", "Comfort", .smart, 0x62,
                           "Reduces flush and dryer noise"))
        list.append(toggle("four_season", "Four-season Sensing", "Comfort", .smart, 0x63,
                           "Adjusts water / air / seat temperature by ambient temperature"))
        list.append(level("user_id", "User ID", "Comfort", .smart, 0x64,
                          1, 4, userLabels, 1, "Per-user memory, avoids mixed settings"))
        list.append(toggle("child_mode", "Child Mode", "Comfort", .smart, 0x65,
                           "Lower water pressure and temperature (if equipped)"))
        list.append(toggle("led_display", "LED Display", "Comfort", .smart, 0x67,
                           "Top LED shows water temp / seat temp / ECO status"))
        list.append(action("self_test", "Self Test", "Comfort", .smart, 0x66,
                           "Read the mainboard self-test status"))

        /* ---------------- SAFETY (hardware, read-only) ---------------- */
        list.append(info("leakage", "Leakage Protection", "Safety", .safety,
                         "Press TEST on the plug once a month"))
        list.append(info("ground", "Ground Protection", "Safety", .safety,
                         "Must use a reliably grounded outlet"))
        list.append(info("backflow", "Anti-backflow", "Safety", .safety,
                         "Anti-backflow and anti-syphon devices"))
        list.append(info("pressure", "Pressure Protection", "Safety", .safety,
                         "High water pressure protection and low-pressure heating cutoff"))
        list.append(info("overheat", "Overheat Protection", "Safety", .safety,
                         "Thermal fuse + thermostat + multi sensors"))
        list.append(info("waterproof", "IPX4 & VO Flame-retardant", "Safety", .safety,
                         "Whole-unit waterproofing and flame-retardant material"))
        list.append(info("gfci", "GFCI Requirement", "Safety", .safety,
                         "110-120V / 15A, GFCI trip current < 6mA"))

        return list
    }
}

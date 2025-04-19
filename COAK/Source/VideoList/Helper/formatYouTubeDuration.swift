//
//  formatYouTubeDuration.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

func formatYouTubeDuration(_ isoDuration: String) -> String {
    var hours = 0, minutes = 0, seconds = 0
    var value = ""
    var isTimeSection = false

    for char in isoDuration {
        if char == "T" {
            isTimeSection = true
            continue
        }
        if char.isNumber {
            value.append(char)
        } else {
            switch char {
            case "H":
                hours = Int(value) ?? 0
            case "M":
                minutes = Int(value) ?? 0
            case "S":
                seconds = Int(value) ?? 0
            default: break
            }
            value = ""
        }
    }

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}

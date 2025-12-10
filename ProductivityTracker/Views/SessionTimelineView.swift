//
//  SessionTimelineView.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import SwiftUI

struct SessionTimelineView: View {
    let session: WorkSession
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let segments = calculateSegments()
                let totalDuration = session.duration
                
                HStack(spacing: 1) {
                    ForEach(segments) { segment in
                        let width = totalDuration > 0 ? (segment.duration / totalDuration) * geometry.size.width : 0
                        
                        ZStack {
                            // Background Box
                            Rectangle()
                                .fill(segment.color)
                            
                            // Duration Text (only if wide enough)
                            if width > 20 {
                                Text(segment.durationString)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: max(0, width))
                    }
                }
            }
            .frame(height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Legend
            HStack(spacing: 12) {
                LegendItem(color: .blue, label: "Focused")
                LegendItem(color: .purple, label: "Recovery")
                LegendItem(color: .orange, label: "Interruption")
            }
        }
    }
    
    private func calculateSegments() -> [TimelineSegment] {
        var segments: [TimelineSegment] = []
        let now = Date()
        let sessionEnd = session.endTime ?? now
        
        // Sort interruptions by start time
        let sortedInterruptions = session.interruptions.sorted { $0.startTime < $1.startTime }
        
        var currentTime = session.startTime
        var penaltyUntil: Date? = nil
        
        for interruption in sortedInterruptions {
            let intStart = interruption.startTime
            
            // Handle time before interruption (Focus or Penalty)
            if currentTime < intStart {
                var ptr = currentTime
                
                // 1. Add Penalty Segment if applicable
                if let pEnd = penaltyUntil, ptr < pEnd {
                    let end = min(pEnd, intStart)
                    segments.append(TimelineSegment(type: .penalty, startTime: ptr, endTime: end))
                    ptr = end
                }
                
                // 2. Add Focus Segment
                if ptr < intStart {
                    segments.append(TimelineSegment(type: .focus, startTime: ptr, endTime: intStart))
                }
            }
            
            // 3. Add Interruption Segment
            let intEnd = interruption.endTime ?? now
            segments.append(TimelineSegment(type: .interruption, startTime: intStart, endTime: intEnd))
            
            currentTime = intEnd
            
            // Set up penalty for next phase
            // Only if the interruption has actually ended
            if interruption.endTime != nil {
                penaltyUntil = intEnd.addingTimeInterval(Double(ProductivityCalculator.recoveryTimeMinutes) * 60)
            } else {
                penaltyUntil = nil // Still interrupted, no penalty scheduled yet
            }
        }
        
        // Handle remaining time after last interruption
        if currentTime < sessionEnd {
            var ptr = currentTime
            
            // 1. Add Penalty Segment if applicable
            if let pEnd = penaltyUntil, ptr < pEnd {
                let end = min(pEnd, sessionEnd)
                segments.append(TimelineSegment(type: .penalty, startTime: ptr, endTime: end))
                ptr = end
            }
            
            // 2. Add Focus Segment
            if ptr < sessionEnd {
                segments.append(TimelineSegment(type: .focus, startTime: ptr, endTime: sessionEnd))
            }
        }
        
        return segments
    }
}

struct TimelineSegment: Identifiable {
    let id = UUID()
    let type: SegmentType
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var durationString: String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
    
    var color: Color {
        switch type {
        case .focus: return .blue
        case .interruption: return .orange
        case .penalty: return .purple
        }
    }
}

enum SegmentType {
    case focus
    case interruption
    case penalty
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

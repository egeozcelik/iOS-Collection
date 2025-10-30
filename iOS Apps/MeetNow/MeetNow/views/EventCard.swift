//
//  EventCard.swift
//  MeetNow
//  Updated version with user location support
//

import SwiftUI
import CoreLocation

struct EventCard: View {
    let event: EventModel
    let userLocation: CLLocation?
    
    init(event: EventModel = EventModel.mockEvent, userLocation: CLLocation? = nil) {
        self.event = event
        self.userLocation = userLocation
    }
    
    var cardGradient: [Color] {
        switch event.icon {
        case "cup.and.saucer.fill":
            return [Color(hex: "6B73FF"), Color(hex: "000DFF")]
        case "figure.run":
            return [Color(hex: "00C9FF"), Color(hex: "92FE9D")]
        case "tv.fill":
            return [Color(hex: "FC466B"), Color(hex: "3F5EFB")]
        case "fork.knife":
            return [Color(hex: "FDBB2D"), Color(hex: "22C1C3")]
        case "music.note":
            return [Color(hex: "667eea"), Color(hex: "764ba2")]
        default:
            return [Color(hex: "4300FF"), Color(hex: "0065F8")]
        }
    }
    
    var bottomGradient: [Color] {
        switch event.icon {
        case "cup.and.saucer.fill":
            return [Color(hex: "00CAFF"), Color(hex: "ACFFAD")]
        case "figure.run":
            return [Color(hex: "FFE53B"), Color(hex: "FF2525")]
        case "tv.fill":
            return [Color(hex: "21D4FD"), Color(hex: "B721FF")]
        case "fork.knife":
            return [Color(hex: "FA709A"), Color(hex: "FEE140")]
        case "music.note":
            return [Color(hex: "f093fb"), Color(hex: "f5576c")]
        default:
            return [Color(hex: "00CAFF"), Color(hex: "00FFDE")]
        }
    }
    
    private var distanceText: String {
        return event.distanceText(from: userLocation)
    }
    
    private var walkingTimeText: String {
        return event.walkingTimeText(from: userLocation)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: cardGradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                HStack(spacing: 12) {
                    Image(systemName: event.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(event.timeText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(walkingTimeText)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            Rectangle()
                .fill(Color.white)
                .frame(height: 60)
                .overlay(
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: event.organizer.profileImageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.organizer.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: event.location.isHidden ? "eye.slash" : "location")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(event.location.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: event.maxParticipants == 0 ? "infinity" : "person.2.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(event.participantStatusText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                            
                            if userLocation != nil {
                                Text(distanceText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                )
            
            ZStack {
                LinearGradient(
                    colors: bottomGradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

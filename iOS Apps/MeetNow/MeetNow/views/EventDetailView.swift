//
//  EventDetailView.swift
//  MeetNow
//
//  Created by Ege Özçelik on 15.08.2025.
//

import SwiftUI


struct EventDetailView: View {
    let event: EventModel
    @Environment(\.dismiss) private var dismiss
    
    private var eventGradient: [Color] {
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
        case "book.fill":
            return [Color(hex: "4facfe"), Color(hex: "00f2fe")]
        default:
            return [Color(hex: "4300FF"), Color(hex: "0065F8")]
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedEventGradientBackground(colors: eventGradient)
            
            ScrollView {
                VStack(spacing: 24) {
                    EventCard(event: event)
                        .padding(.horizontal)
                    
                    VStack(spacing: 20) {
                        GlassContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("About this event")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                Text(event.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                            }
                            .padding(20)
                        }
                        
                        GlassContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text("Participants")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(event.currentParticipants)/\(event.maxParticipants)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                                
                                if event.currentParticipants > 1 {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Who's joining:")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        HStack(spacing: -8) {
                                            ForEach(0..<min(event.currentParticipants, 5), id: \.self) { index in
                                                AsyncImage(url: URL(string: "https://picsum.photos/20\(index)/20\(index)")) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.3))
                                                }
                                                .frame(width: 32, height: 32)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                            }
                                            
                                            if event.currentParticipants > 5 {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.3))
                                                        .frame(width: 32, height: 32)
                                                    
                                                    Text("+\(event.currentParticipants - 5)")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                        }
                        
                        GlassContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text("Location")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(event.location.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(event.location.address)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .font(.caption)
                                        Text("Open in Maps")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(20)
                        }
                        
                        GlassContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    
                                    Text("Time")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                Text(event.timeText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(20)
                        }
                        
                        Button(action: {}) {
                            Text("Request to Join")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: eventGradient,
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(event.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }
}

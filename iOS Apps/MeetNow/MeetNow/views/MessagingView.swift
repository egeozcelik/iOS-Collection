//
//  MessagingView.swift
//  MeetNow
//
//  Created by Ege Özçelik on 13.08.2025.
//
import SwiftUI

struct ConversationListView: View {
    @StateObject private var viewModel = ConversationViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFFCA")
                    .ignoresSafeArea()
                
                if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No conversations yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Join an event to start chatting!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadConversations()
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: conversation.otherUser.profileImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(conversation.lastMessageTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(conversation.eventTitle)
                    .font(.caption)
                    .foregroundColor(Color(hex: "4300FF"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "4300FF").opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showEventBanner {
                EventRequestBanner(
                    user: conversation.otherUser,
                    eventTitle: conversation.eventTitle,
                    canAddToEvent: viewModel.hasReplied
                ) {
                    viewModel.sharePhoneNumber()
                } addToEvent: {
                    viewModel.addUserToEvent()
                }
                .background(Color(hex: "FAFFCA"))
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            .background(Color(hex: "FAFFCA"))
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            messageText.isEmpty ?
                            AnyShapeStyle(Color.gray.opacity(0.5)) :
                            AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        )
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color.white)
        }
        .navigationTitle(conversation.otherUser.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages(for: conversation)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(messageText)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                
                Text(message.text)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "4300FF"), Color(hex: "0065F8")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

struct EventRequestBanner: View {
    let user: User
    let eventTitle: String
    let canAddToEvent: Bool
    let onSharePhone: () -> Void
    let addToEvent: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: user.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Wants to join: \(eventTitle)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: addToEvent) {
                    Text("Add to Event")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            canAddToEvent ?
                            LinearGradient(
                                colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .disabled(!canAddToEvent)
            }
            
            Button(action: onSharePhone) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                    Text("Share Phone Number")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color(hex: "4300FF"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "4300FF"), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(hex: "4300FF").opacity(0.1), Color(hex: "00CAFF").opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}





class ConversationViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    func loadConversations() {
        conversations = []
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var showEventBanner = true
    @Published var hasReplied = false
    
    func loadMessages(for conversation: Conversation) {
        messages = [
            Message(id: "1", text: "Hi! I'd like to join your event", isFromCurrentUser: false, timestamp: Date())
        ]
    }
    
    func sendMessage(_ text: String) {
        let message = Message(id: UUID().uuidString, text: text, isFromCurrentUser: true, timestamp: Date())
        messages.append(message)
        hasReplied = true
    }
    
    func sharePhoneNumber() {
        let message = Message(id: UUID().uuidString, text: "My phone number: +1234567890", isFromCurrentUser: true, timestamp: Date())
        messages.append(message)
    }
    
    func addUserToEvent() {
        print("User added to event")
    }
}

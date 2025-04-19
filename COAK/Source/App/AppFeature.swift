//
//  AppFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import Foundation
import FirebaseAuth
import FirebaseFirestore

enum LogoutError: Error, Equatable {
    case unknown
}

struct AppFeature: Reducer {
    struct State: Equatable {
        var mainTab = MainTabFeature.State()
        var auth = AuthFeature.State()
        
        var isLoading: Bool = true
        var isSignedIn: Bool = false
        var isAdmin: Bool = false
        var isProfileIncomplete = false
        
        var userProfile: UserProfile? = nil
        
        var hasLoadedFavorites: Bool = false
        var favoriteVideoIDs: Set<String> = []
        var favoriteVideos: [FavoriteVideo] = []
        
    }
    
    enum Action: Equatable {
        case mainTab(MainTabFeature.Action)
        case auth(AuthFeature.Action)
        
        case checkProfileCompleteness
        case profileCheckResult(Bool)
        
        case onLaunch
        case authChecked(Bool)
        case adminChecked(Bool)
        
        case loadUserProfile
        case userProfileLoaded(UserProfile)
        
        case favoritesLoaded(Set<String>, [FavoriteVideo])
        case addToFavorites(YouTubeVideo)
        case removeFromFavorites(String)
        
        case logoutTapped
        case logoutSucceeded
        case logoutFailed(LogoutError)
    }
    
    @Dependency(\.favoritesClient) var favoritesClient
    
    var body: some Reducer<State, Action> {
        Scope(state: \.mainTab, action: /Action.mainTab) { MainTabFeature() }
        Scope(state: \.auth, action: /Action.auth) { AuthFeature() }
        
        Reduce { state, action in
            switch action {
            case .onLaunch:
                state.isLoading = true
                return .run { send in
                    let isSignedIn = Auth.auth().currentUser != nil
                    await send(.authChecked(isSignedIn))
                }
                
            case .authChecked(let isSignedIn):
                state.isSignedIn = isSignedIn
                state.isLoading = false
                
                guard isSignedIn, let user = Auth.auth().currentUser else {
                    return .none
                }

                return .run { send in
                    let favorites = try await favoritesClient.loadFavorites(user.uid)
                    async let isAdmin = checkIfAdmin(user.uid)
                    
                    let (favs, admin) = await (favorites, isAdmin)
                    
                    let ids = Set(favs.map { $0.id })
                    await send(.loadUserProfile)
                    await send(.favoritesLoaded(ids, favs))
                    await send(.adminChecked(admin))
                }
                
            case .loadUserProfile:
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                return .run { send in
                    let doc = try? await Firestore.firestore().collection("users").document(uid).getDocument()
                    let data = doc?.data()
                    let name = data?["name"] as? String
                    let phone = data?["phone"] as? String
                    let birth = data?["birthdate"] as? Timestamp
                    let incomplete = (name?.isEmpty ?? true) || (phone?.isEmpty ?? true) || (birth == nil)
                    await send(.profileCheckResult(incomplete))
                }
                
            case let .userProfileLoaded(userProfile):
                state.userProfile = userProfile
                return .none
                
            case .checkProfileCompleteness:
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                return .run { send in
                    let doc = try? await Firestore.firestore().collection("users").document(uid).getDocument()
                    let data = doc?.data()
                    let name = data?["name"] as? String
                    let phone = data?["phone"] as? String
                    let birth = data?["birthdate"] as? Timestamp
                    let incomplete = (name?.isEmpty ?? true) || (phone?.isEmpty ?? true) || (birth == nil)
                    await send(.profileCheckResult(incomplete))
                }

            case let .profileCheckResult(incomplete):
                state.isProfileIncomplete = incomplete
                return .none
                
            case let .adminChecked(isAdmin):
                state.isAdmin = isAdmin
                return .none
                
            case .auth(.loginSucceeded):
                return .send(.authChecked(true))
                
            case let .favoritesLoaded(ids, videos):
                state.favoriteVideoIDs = ids
                state.favoriteVideos = videos
                state.hasLoadedFavorites = true
                return .none
                
            case let .addToFavorites(video):
                guard let user = Auth.auth().currentUser else { return .none }
                state.favoriteVideoIDs.insert(video.id)
                state.favoriteVideos.append(FavoriteVideo(
                    id: video.id,
                    title: video.title,
                    description: video.description,
                    thumbnailURL: URL(string: video.thumbnailURL),
                    userId: user.uid,
                    createdAt: Date()
                ))
                return .run { _ in
                    let favorite = FavoriteVideo(
                        id: video.id,
                        title: video.title,
                        description: video.description,
                        thumbnailURL: URL(string: video.thumbnailURL),
                        userId: user.uid,
                        createdAt: Date()
                    )
                    try Firestore.firestore()
                        .collection("favorites")
                        .document("\(user.uid)_\(video.id)")
                        .setData(from: favorite)
                }
                
            case let .removeFromFavorites(videoId):
                guard let user = Auth.auth().currentUser else { return .none }
                state.favoriteVideoIDs.remove(videoId)
                state.favoriteVideos.removeAll { $0.id == videoId }
                return .run { _ in
                    try await Firestore.firestore()
                        .collection("favorites")
                        .document("\(user.uid)_\(videoId)")
                        .delete()
                }
                
            case .logoutTapped:
                return .run { send in
                    do {
                        try Auth.auth().signOut()
                        await send(.logoutSucceeded)
                    } catch {
                        await send(.logoutFailed(error as! LogoutError))
                    }
                }
                
            case .logoutSucceeded:
                state.isSignedIn = false
                state.favoriteVideoIDs = []
                state.favoriteVideos = []
                state.hasLoadedFavorites = false
                return .none
                
            case let .logoutFailed(error):
                // 로그아웃 실패 처리 (optional)
                print("로그아웃 실패: \(error)")
                return .none
                
            default:
                return .none
            }
        }
    }
}

// MARK: - 관리자 확인 함수

private func checkIfAdmin(_ uid: String) async -> Bool {
    let ref = Firestore.firestore().collection("admins").document(uid)
    do {
        let snapshot = try await ref.getDocument()
        return snapshot.exists
    } catch {
        print("⚠️ 관리자 확인 실패:", error)
        return false
    }
}

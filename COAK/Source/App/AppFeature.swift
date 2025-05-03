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

enum CustomError: Error, Equatable {
    case unknown
}

struct AppFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var mainTab = MainTabFeature.State()
        var auth = AuthFeature.State()
        var playlistEdit = PlaylistEditFeature.State()
        
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
        case playlistEdit(PlaylistEditFeature.Action)
        
        case checkProfileCompleteness
        case profileCheckResult(Bool)
        
        case onLaunch
        case authChecked(Bool)
        case adminChecked(Bool)
        
        case loadUserProfile
        case userProfileLoaded(UserProfile)
        
        case loadFavorites
        case loadFavoritesResponse(Result<[FavoriteVideo], CustomError>)
        
        case addToFavorites(YouTubeVideo)
        case removeFromFavorites(String)
        case addFavoritesResponse(Result<FavoriteVideo, CustomError>)
        case removeFavoritesResponse(Result<String, CustomError>)
        
        case logoutTapped
        case logoutSucceeded
        case logoutFailed(CustomError)
    }
    
    @Dependency(\.favoritesClient) var favoritesClient
    
    var body: some Reducer<State, Action> {
        Scope(state: \.mainTab, action: /Action.mainTab) { MainTabFeature() }
        Scope(state: \.auth, action: /Action.auth) { AuthFeature() }
        Scope(state: \.playlistEdit, action: /Action.playlistEdit) { PlaylistEditFeature() }
        
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
                    async let isAdmin = checkIfAdmin(user.uid)
                    
                    let admin = await isAdmin
                    
                    await send(.loadUserProfile)
                    await send(.loadFavorites)
                    await send(.adminChecked(admin))
                }
                
            case .loadUserProfile:
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                return .run { send in
                    let doc = try? await Firestore.firestore().collection("users").document(uid).getDocument()
                    let data = doc?.data()
                    let name = data?["name"] as? String
                    let email = data?["email"] as? String
                    let phone = data?["phone"] as? String
                    let birth = data?["birthdate"] as? Timestamp
                    let profileImageURL = data?["profileImageURL"] as? String
                    let incomplete = (name?.isEmpty ?? true) || (phone?.isEmpty ?? true) || (birth == nil)
                    let userProfile = UserProfile(
                        uid: uid,
                        name: name ?? "",
                        email: email ?? "",
                        birthdate: birth?.dateValue(),
                        phone: phone ?? "",
                        profileImageURL: profileImageURL ?? "",
                        createdAt: nil,
                        allowNotifications: incomplete,
                        isPremium: false
                    )
                    await send(.userProfileLoaded(userProfile))
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
                
                
            case .loadFavorites:
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                return .run { send in
                    let videos = try await favoritesClient.fetchFavorites(uid)
                    await send(.loadFavoritesResponse(.success(videos)))
                } catch: { error, send in
                    await send(.loadFavoritesResponse(.failure(error as! CustomError)))
                }

            case let .loadFavoritesResponse(.success(videos)):
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                for video in videos {
                    state.favoriteVideos.append(FavoriteVideo(
                        id: video.id,
                        title: video.title,
                        description: video.description,
                        thumbnailURL: video.thumbnailURL,
                        userId: uid,
                        createdAt: Date()
                    ))
                }
                state.favoriteVideoIDs = Set(videos.map(\ .id))
                state.hasLoadedFavorites = true
                return .none
                
            case let .addToFavorites(video):
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                let favorite = FavoriteVideo(id: video.id, title: video.title, description: video.description, thumbnailURL: URL(string: video.thumbnailURL), userId: uid, createdAt: Date())
                return .run { send in
                    try await favoritesClient.addFavorite(uid, favorite)
                    await send(.addFavoritesResponse(.success(favorite)))
                } catch: { error, send in
                    await send(.addFavoritesResponse(.failure(error as! CustomError)))
                }
                
            case let .addFavoritesResponse(.success(video)):
                state.favoriteVideos.append(video)
                state.favoriteVideoIDs.insert(video.id)
                return .none
                
            case let .removeFromFavorites(id):
                guard let uid = Auth.auth().currentUser?.uid else { return .none }
                return .run { send in
                    try await favoritesClient.removeFavorite(uid, id)
                    await send(.removeFavoritesResponse(.success(id)))
                } catch: { error, send in
                    await send(.removeFavoritesResponse(.failure(error as! CustomError)))
                }
                
            case let .removeFavoritesResponse(.success(id)):
                state.favoriteVideos.removeAll { $0.id == id }
                state.favoriteVideoIDs.remove(id)
                return .none
                
            case .logoutTapped:
                return .run { send in
                    do {
                        try Auth.auth().signOut()
                        await send(.logoutSucceeded)
                    } catch {
                        await send(.logoutFailed(error as! CustomError))
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
                
            case .mainTab, .auth, .playlistEdit: return .none
            case .addFavoritesResponse(.failure), .removeFavoritesResponse(.failure), .loadFavoritesResponse(.failure):
                return .none // TODO: 에러 핸들링 로깅
            
                
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

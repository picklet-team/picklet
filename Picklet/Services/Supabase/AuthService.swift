//
//
//

import Foundation
import Supabase
import SwiftUI

class AuthService {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    static let shared = AuthService()
    
    internal let client: SupabaseClient
    
    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("❌ Supabaseの設定がInfo.plistにありません")
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
    
    var currentUser: User? {
        client.auth.currentUser
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        isLoggedIn = true
    }
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
        isLoggedIn = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        isLoggedIn = false
    }
}

// SupabaseConfig — the project the web app uses (same accounts, same data).
// The key is the publishable client key the website ships to every browser;
// row-level security on the server decides what it may read or write.

import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://chpoqghvlojwyunoplab.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNocG9xZ2h2bG9qd3l1bm9wbGFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzAyODIsImV4cCI6MjA4ODY0NjI4Mn0.r_1JeIDnRpKiTWn74bCHBFUU7kOu4YSPFY9QRjrdPX0"
    /// Website endpoints the app calls (account deletion).
    static let site = URL(string: "https://jazzchords.app")!

    /// One client for the app; its auth session lives in the Keychain and refreshes itself.
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey,
        options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
    )
}

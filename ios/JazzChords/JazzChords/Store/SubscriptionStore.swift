// SubscriptionStore — Pro entitlement gate. v1 ships every feature unlocked (no
// in-app charge), so this returns true; the structure mirrors the web's gating so
// real StoreKit 2 can drop in later (load Product, observe Transaction.updates,
// set `isPro` from the entitlement) without touching call sites.

import Foundation
import Observation

@MainActor
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    /// v1: all features free. Flip to a real StoreKit entitlement before charging.
    private(set) var isPro = true

    private init() {}

    /// Features that are Pro on the web (custom progressions, adaptive coaching).
    func canUse(_ feature: String) -> Bool {
        // While unlocked, everything is allowed. Keeps gate call-sites in place.
        return isPro
    }

    // MARK: StoreKit 2 (to wire when monetizing iOS)
    // - Load Product(s) for the Pro subscription id.
    // - Listen to Transaction.updates; set isPro from current entitlements.
    // - purchase() / restore() methods feeding isPro.
}

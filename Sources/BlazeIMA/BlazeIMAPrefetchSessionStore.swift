//
//  BlazeIMAPrefetchSessionStore.swift
//  BlazeIMA
//
//  Copyright © 2026 com.WSCSports. All rights reserved.
//

import Foundation
import GoogleInteractiveMediaAds

/// Thread-safe owner of all prefetch bookkeeping: active sessions, cancellation tombstones,
/// and the session cap. Every method is one atomic operation under a single lock — callers
/// never compose "check + act" across two calls, which is what keeps the invariants below
/// enforceable in exactly one place:
///
/// - A token has at most one session (`reserve` rejects duplicates).
/// - A tombstone is consumed exactly once — by the pending `prefetchAds` (`reserve`) or by
///   the late loader callback (`consumeTombstone`).
/// - A session is handed out for activation at most once (`takeReady` removes it).
///
/// The store knows nothing about IMA flows, UIKit, or the main thread; the handler owns all
/// side effects (destroy/detach/delegate events) and calls the store only for state decisions.
final class BlazeIMAPrefetchSessionStore {

    enum ReserveResult: Equatable {
        case inserted
        /// A pending tombstone was consumed by this attempt — the slot was cancelled
        /// while its `prefetchAds` was still in flight.
        case declinedCancelled
        /// A session for this token already exists.
        case declinedDuplicate
        /// The session cap is reached.
        case declinedCapReached
    }

    private let lock = NSLock()
    /// Active prefetch sessions keyed by token (background requests not yet shown).
    private var sessions: [String: BlazeIMAPrefetchSession] = [:]
    /// Tombstones for prefetches cancelled while their work is still pending — either the ad
    /// request is in flight (session was `.requesting`) or `prefetchAds` is still inside its
    /// awaits (no session yet). Without them the late loader callback finds no session and
    /// falls into the live flow. Insertion-dated and pruned on insert: a tombstone whose
    /// response never arrives has no consumer and would otherwise accumulate forever.
    private var tombstones: [String: Date] = [:]

    private let maxSessions: Int
    private let tombstoneTTL: TimeInterval
    /// Current-time source. Injectable so tombstone TTL pruning is deterministic in tests.
    private let now: () -> Date

    init(maxSessions: Int,
         tombstoneTTL: TimeInterval = 120,
         now: @escaping () -> Date = { Date() }) {
        self.maxSessions = maxSessions
        self.tombstoneTTL = tombstoneTTL
        self.now = now
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    // MARK: - Compound operations

    /// `prefetchAds`' admission check and insertion as one atomic step:
    /// consume a pending tombstone / reject a duplicate / enforce the cap / insert.
    func reserve(_ session: BlazeIMAPrefetchSession) -> ReserveResult {
        withLock {
            if tombstones.removeValue(forKey: session.token) != nil { return .declinedCancelled }
            if sessions[session.token] != nil { return .declinedDuplicate }
            if sessions.count >= maxSessions { return .declinedCapReached }
            sessions[session.token] = session
            return .inserted
        }
    }

    /// `cancelPrefetch`: remove the session or plant a tombstone — one decision under one lock.
    /// No session yet (a `prefetchAds` still inside its awaits, or nothing to cancel) → tombstone.
    /// A `.requesting` session → removed AND tombstoned, so its in-flight loader callback is
    /// dropped instead of leaking into the live flow.
    func removeOrTombstone(_ token: String) -> BlazeIMAPrefetchSession? {
        withLock {
            guard let session = sessions.removeValue(forKey: token) else {
                insertTombstoneLocked(token)
                return nil
            }
            if case .requesting = session.status {
                insertTombstoneLocked(token)
            }
            return session
        }
    }

    /// Loader callbacks: "was this prefetch cancelled?" — consumes the tombstone.
    func consumeTombstone(_ token: String) -> Bool {
        withLock { tombstones.removeValue(forKey: token) != nil }
    }

    /// `activatePrefetchedAd`: take the ready session and remove it atomically, so a session
    /// can never be activated twice.
    func takeReady(_ token: String) -> (session: BlazeIMAPrefetchSession, manager: IMAAdsManager, ad: IMAAd?)? {
        withLock {
            guard let session = sessions[token],
                  case .ready(let manager, let ad) = session.status else { return nil }
            sessions.removeValue(forKey: token)
            return (session, manager, ad)
        }
    }

    // MARK: - Status transitions

    /// Loader delivered a manager: `.requesting` → `.loading`. Returns `false` when the
    /// session is gone (cancelled meanwhile) so the caller must not wire the manager up.
    func markLoading(_ token: String, manager: IMAAdsManager) -> Bool {
        withLock {
            guard sessions[token] != nil else { return false }
            sessions[token]?.status = .loading(adsManager: manager)
            return true
        }
    }

    /// Manager fired `.LOADED`: `.loading` → `.ready`, keeping the stored manager.
    func markReady(_ token: String, ad: IMAAd?) {
        withLock {
            if case .loading(let manager)? = sessions[token]?.status {
                sessions[token]?.status = .ready(adsManager: manager, ad: ad)
            }
        }
    }

    /// Loader delivered an empty response (no manager).
    func markNoFill(_ token: String) {
        withLock { sessions[token]?.status = .noFill }
    }

    /// Loader failed for a live session. Returns `false` when no session exists, so the
    /// caller can route the error to the live flow instead.
    func markLoadFailure(_ token: String, isNoFill: Bool, message: String) -> Bool {
        withLock {
            guard sessions[token] != nil else { return false }
            sessions[token]?.status = isNoFill ? .noFill : .error(message: message)
            return true
        }
    }

    /// A held manager errored after creation.
    func markError(_ token: String, message: String) {
        withLock { sessions[token]?.status = .error(message: message) }
    }

    // MARK: - Queries

    func hasSession(_ token: String) -> Bool {
        withLock { sessions[token] != nil }
    }

    func status(_ token: String) -> IMAPrefetchStatus? {
        withLock { sessions[token]?.status }
    }

    /// Full session for the token (nil if none). The handler needs its `adTagUrl`/`extraInfo`
    /// for `adInfo`, which `status` alone doesn't carry.
    func session(_ token: String) -> BlazeIMAPrefetchSession? {
        withLock { sessions[token] }
    }

    /// Reverse lookup for `IMAAdsManagerDelegate` routing: prefetch managers are identified
    /// by identity against the managers stored in `.loading`/`.ready` sessions.
    func token(for manager: IMAAdsManager) -> String? {
        withLock {
            for (token, session) in sessions {
                switch session.status {
                case .loading(let stored) where stored === manager,
                     .ready(let stored, _) where stored === manager:
                    return token
                default:
                    continue
                }
            }
            return nil
        }
    }

    /// `true` while any session is in-flight or held (`.requesting`/`.loading`/`.ready`) —
    /// the states in which `contentComplete()` on the shared loader is unsafe.
    func hasActiveSessions() -> Bool {
        withLock {
            sessions.values.contains { session in
                switch session.status {
                case .requesting, .loading, .ready: return true
                case .noFill, .error: return false
                }
            }
        }
    }

    // MARK: - Private

    /// Must be called while holding `lock`. Prunes expired tombstones on the way in.
    private func insertTombstoneLocked(_ token: String) {
        let currentDate = now()
        let cutoff = currentDate.addingTimeInterval(-tombstoneTTL)
        tombstones = tombstones.filter { $0.value > cutoff }
        tombstones[token] = currentDate
    }
}

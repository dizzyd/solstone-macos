// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (c) 2026 sol pbc

import Testing
@testable import solstone

@Suite("Permission outcome")
struct PermissionOutcomeTests {
    @Test func screenRecordingChecksAreCheckingBeforeInitialPass() {
        #expect(PermissionOutcome.screenRecording(
            initialPermissionCheckComplete: false,
            screenRecordingGranted: false,
            hasPromptedScreenRecording: false,
            preflightSucceeded: false,
            sckFailedAfterPositivePreflight: false
        ) == .checking)
    }

    @Test func screenRecordingGrantedAfterRealSuccess() {
        #expect(PermissionOutcome.screenRecording(
            initialPermissionCheckComplete: true,
            screenRecordingGranted: true,
            hasPromptedScreenRecording: true,
            preflightSucceeded: true,
            sckFailedAfterPositivePreflight: false
        ) == .granted)
        #expect(PermissionOutcome.screenRecording(
            initialPermissionCheckComplete: true,
            screenRecordingGranted: false,
            hasPromptedScreenRecording: true,
            preflightSucceeded: true,
            sckFailedAfterPositivePreflight: false
        ) == .granted)
    }

    @Test func screenRecordingConclusiveNotGrantedDoesNotBecomeUnavailable() {
        #expect(PermissionOutcome.screenRecording(
            initialPermissionCheckComplete: true,
            screenRecordingGranted: false,
            hasPromptedScreenRecording: true,
            preflightSucceeded: false,
            sckFailedAfterPositivePreflight: false
        ) == .notGranted)
    }

    @Test func screenRecordingPositivePreflightSCKFailureIsUnavailable() {
        #expect(PermissionOutcome.screenRecording(
            initialPermissionCheckComplete: true,
            screenRecordingGranted: false,
            hasPromptedScreenRecording: true,
            preflightSucceeded: true,
            sckFailedAfterPositivePreflight: true
        ) == .unavailable)
    }

    @Test func microphoneOutcomesDistinguishCauses() {
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: false,
            microphoneGranted: false,
            cause: .notDetermined
        ) == .checking)
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: true,
            microphoneGranted: true,
            cause: .unknown
        ) == .granted)
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: true,
            microphoneGranted: false,
            cause: .notDetermined
        ) == .notGranted)
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: true,
            microphoneGranted: false,
            cause: .denied
        ) == .notGranted)
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: true,
            microphoneGranted: false,
            cause: .restricted
        ) == .notGranted)
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: true,
            microphoneGranted: false,
            cause: .unknown
        ) == .unavailable)
    }

    /// `microphoneGranted` is captured at launch and reloads only on app restart, so a
    /// grant made while the app is running leaves it stale. The live cause is the durable
    /// fact and must win, otherwise settings reports a granted mic as unavailable.
    @Test func microphoneTrustsLiveAuthorizationOverStaleLaunchCache() {
        #expect(PermissionOutcome.microphone(
            initialPermissionCheckComplete: true,
            microphoneGranted: false,
            cause: .authorized
        ) == .granted)
    }
}

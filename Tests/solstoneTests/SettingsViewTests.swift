import Testing
@testable import solstone

@Suite("SettingsView")
struct SettingsViewTests {
    @Test func tabRawValuesMatchCaseNames() {
        #expect(SettingsView.Tab.permissions.rawValue == "permissions")
        #expect(SettingsView.Tab.observer.rawValue == "observer")
        #expect(SettingsView.Tab.service.rawValue == "service")
        #expect(SettingsView.Tab.microphones.rawValue == "microphones")
        #expect(SettingsView.Tab.privacy.rawValue == "privacy")
        #expect(SettingsView.Tab.status.rawValue == "status")
        #expect(SettingsView.Tab.updates.rawValue == "updates")
        #expect(SettingsView.Tab.help.rawValue == "help")
    }

    /// Both panes read `setupProbeSnapshot`. Without a refresh on appear the permissions
    /// pane renders `SetupProbeSnapshot.checking`, whose placeholder `microphoneCause` is
    /// `.unknown` — reported to the owner as "couldn't check" no matter what the OS says,
    /// and immune to a `tccutil reset` because nothing on that path reads TCC.
    @Test func statusAndPermissionsPanesRefreshProbesOnAppear() throws {
        let source = try readWireUpSource("Sources/solstone/SettingsView.swift")
        let detailContent = try extract(
            from: source,
            start: "private var detailContent: some View",
            end: "    private func applyPendingSettingsTab"
        )

        let permissionsCase = try extract(
            from: detailContent,
            start: "case .permissions:",
            end: "case .updates:"
        )
        #expect(permissionsCase.contains("refreshSetupProbes()"))

        let statusCase = try extract(
            from: detailContent,
            start: "case .status:",
            end: "case .observer:"
        )
        #expect(statusCase.contains("refreshSetupProbes()"))
    }

    @Test func journalPaneRendersClientPanelBranches() throws {
        let source = try readWireUpSource("Sources/solstone/SettingsView.swift")
        let serviceSection = try extract(
            from: source,
            start: "private var serviceSection: some View",
            end: "    @ViewBuilder\n    private var configuredJournalPanel"
        )

        #expect(serviceSection.contains(#"Text("your journal")"#))
        #expect(serviceSection.contains("journalMigrationBanner"))
        #expect(serviceSection.contains("configuredJournalPanel"))
        #expect(serviceSection.contains("unconfiguredJournalPanel"))
        #expect(!serviceSection.contains("journalModePicker"))
        #expect(!serviceSection.contains("bundledJournalStatusSection"))
    }

    @Test func configuredJournalPanelKeepsAdvancedAndCacheControls() throws {
        let source = try readWireUpSource("Sources/solstone/SettingsView.swift")
        let configuredPanel = try extract(
            from: source,
            start: "private var configuredJournalPanel: some View",
            end: "    @ViewBuilder\n    private var unconfiguredJournalPanel"
        )

        #expect(configuredPanel.contains("DisclosureGroup(\"advanced\")"))
        #expect(configuredPanel.contains("externalServiceSection"))
        #expect(configuredPanel.contains("externalJournalSyncSection"))
        #expect(configuredPanel.contains("externalJournalStorageSection"))
    }

    @Test func statusPaneHidesStorageControlsInBundledMode() throws {
        let source = try readWireUpSource("Sources/solstone/SettingsView.swift")
        let statusTab = try extract(
            from: source,
            start: "private var statusTab: some View",
            end: "    #if DEBUG"
        )
        let beforeExternalStorageGate = try extract(
            from: statusTab,
            start: "setupGroup",
            end: "if resolvedServiceMode(for: appState.config) == .external"
        )
        let externalStorageGate = try extract(
            from: statusTab,
            start: "if resolvedServiceMode(for: appState.config) == .external",
            end: "Text(statusFooterText)"
        )

        #expect(statusTab.contains("setupGroup"))
        #expect(!statusTab.contains("GroupBox(\"journal\")"))
        #expect(!beforeExternalStorageGate.contains("AXID.Settings.Status.storageSettings"))
        #expect(externalStorageGate.contains("AXID.Settings.Status.storageSettings"))
    }

    @Test func journalMigrationBannerUsesHandoffStartOnly() throws {
        let source = try readWireUpSource("Sources/solstone/SettingsView.swift")
        let banner = try extract(
            from: source,
            start: "private var journalMigrationBanner: some View",
            end: "    private var resolvedJournalName"
        )
        let headline = "your journal is getting " + "its own app"
        let body = "nothing moved. your journal was always here. " + "now it has a name."
        let buffering = "segments are kept on this mac " + "until your journal is back"
        let removedButton = "Button(\"not " + "now\")"
        let removedAction = "acknowledgeJournal" + "MigrationBanner"

        #expect(banner.contains("Text(\"\(headline)\")"))
        #expect(banner.contains("Text(\"\(body)\")"))
        #expect(banner.contains("Text(\"\(buffering)\")"))
        #expect(banner.contains("journalHandoffOrchestrator.start"))
        #expect(banner.contains("AXID.Settings.Service.journalHandoffStart"))
        #expect(banner.contains("AXID.Settings.Service.journalHandoffState"))
        #expect(!banner.contains(removedButton))
        #expect(!banner.contains(removedAction))
    }

    private func extract(from source: String, start: String, end: String) throws -> String {
        let startRange = try #require(source.range(of: start))
        let endRange = try #require(source[startRange.upperBound...].range(of: end))
        return String(source[startRange.lowerBound..<endRange.lowerBound])
    }
}

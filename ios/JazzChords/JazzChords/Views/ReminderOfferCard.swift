// ReminderOfferCard — the app's own "remind me tomorrow?" card, shown once after
// the first finished drill (pre-permission: only "Yes" triggers the one-time
// system dialog, so a "Not now" here never burns it). Renders nothing when the
// offer is not due.

import SwiftUI
import MusicEngine

struct ReminderOfferCard: View {
    @Environment(\.palette) private var palette

    private enum Phase { case hidden, offering, enabled, denied }
    @State private var phase: Phase = .hidden
    @State private var busy = false

    private var scheduler: ReminderScheduler { .shared }

    var body: some View {
        Group {
            switch phase {
            case .hidden:
                // Not EmptyView: SwiftUI creates no view for it, so the `.task`
                // below would never run and the offer could never appear.
                Color.clear.frame(height: 0)
            case .offering:
                offer
            case .enabled:
                Label(CoachL10n.t("reminder.offer_enabled", ["time": scheduler.time.string]),
                      systemImage: "bell.badge.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.music)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.space4)
                    .groupSurface()
            case .denied:
                Text(CoachL10n.t("reminder.offer_denied"))
                    .font(.footnote)
                    .foregroundStyle(palette.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.space4)
                    .groupSurface()
            }
        }
        .task {
            // Decide once per appearance, so the card never pops in or out mid-read.
            await scheduler.refreshAuthorization()
            if scheduler.shouldOfferPrompt {
                scheduler.markPromptShown()
                withAnimation { phase = .offering }
            }
        }
    }

    private var offer: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            HStack(alignment: .top, spacing: Theme.space3) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(palette.action)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: Theme.space1) {
                    Text(CoachL10n.t("reminder.offer_title"))
                        .font(Display.serif(22, relativeTo: .headline))
                        .foregroundStyle(palette.ink)
                    Text(CoachL10n.t("reminder.offer_body", ["time": scheduler.time.string]))
                        .font(.subheadline)
                        .foregroundStyle(palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: Theme.space3) {
                Button {
                    busy = true
                    Task {
                        let on = await scheduler.enable()
                        busy = false
                        withAnimation { phase = on ? .enabled : .denied }
                    }
                } label: {
                    Text(CoachL10n.t("reminder.offer_yes"))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space3)
                        .background(palette.action)
                        .foregroundStyle(palette.onAction)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
                .disabled(busy)
                Button {
                    scheduler.decline()
                    withAnimation { phase = .hidden }
                } label: {
                    Text(CoachL10n.t("reminder.offer_no"))
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space3)
                        .foregroundStyle(palette.inkMuted)
                }
                .disabled(busy)
            }
        }
        .padding(Theme.space4)
        .groupSurface()
    }
}

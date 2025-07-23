// LoopFollow
// SnoozerView.swift
// Created by Jonas Björkert.

import SwiftUI

struct SnoozerView: View {
    @StateObject private var vm = SnoozerViewModel()

    @ObservedObject var showDisplayName = Storage.shared.showDisplayName
    @ObservedObject var minAgoText = Observable.shared.minAgoText
    @ObservedObject var bgText = Observable.shared.bgText
    @ObservedObject var bgTextColor = Observable.shared.bgTextColor
    @ObservedObject var directionText = Observable.shared.directionText
    @ObservedObject var deltaText = Observable.shared.deltaText
    @ObservedObject var bgStale = Observable.shared.bgStale
    @ObservedObject var bg = Observable.shared.bg
    @ObservedObject var snoozerEmoji = Storage.shared.snoozerEmoji

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)

                let isLandscape = geo.size.width > geo.size.height

                Group {
                    if isLandscape {
                        HStack(spacing: 0) {
                            leftColumn(isLandscape: true)
                            rightColumn(isLandscape: true)
                        }
                    } else {
                        VStack(spacing: 0) {
                            leftColumn(isLandscape: false)
                            rightColumn(isLandscape: false)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    // MARK: - Left Column (BG / Direction / Delta / Age)

    private func leftColumn(isLandscape: Bool) -> some View {
        VStack(spacing: 0) {
            if !isLandscape && showDisplayName.value {
                Text(Bundle.main.displayName)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }

            Text(bgText.value)
                .font(.system(size: 300, weight: .black))
                .minimumScaleFactor(0.5)
                .foregroundColor(bgTextColor.value)
                .strikethrough(
                    bgStale.value,
                    pattern: .solid,
                    color: bgStale.value ? .red : .clear
                )
                .frame(maxWidth: .infinity, maxHeight: 240)

            if isLandscape {
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    Text(directionText.value)
                        .font(.system(size: 90, weight: .black))

                    Text(deltaText.value)
                        .font(.system(size: 70))
                }
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: 80)

            } else {
                Text(directionText.value)
                    .font(.system(size: 110, weight: .black))
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: 80)

                Text(deltaText.value)
                    .font(.system(size: 70))
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: 68)
            }

            Text(minAgoText.value)
                .font(.system(size: 60))
                .minimumScaleFactor(0.5)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, maxHeight: 40)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    // MARK: - Right Column (Clock/Alert + Snooze Controls)

    private func rightColumn(isLandscape: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer()
            if showDisplayName.value && isLandscape {
                Text(Bundle.main.displayName)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 8)
            }

            if let alarm = vm.activeAlarm {
                VStack(spacing: 16) {
                    Text(alarm.name)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 20)
                    Divider()

                    // snooze controls
                    if alarm.type.snoozeTimeUnit != .none {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Snooze for")
                                    .font(.headline)
                                Text("\(vm.snoozeUnits) \(vm.timeUnitLabel)")
                                    .font(.title3).bold()
                            }
                            Spacer()
                            Stepper("", value: $vm.snoozeUnits,
                                    in: alarm.type.snoozeRange,
                                    step: alarm.type.snoozeStep)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 24)
                    }

                    Button(action: vm.snoozeTapped) {
                        Text(vm.snoozeUnits == 0 ? "Acknowledge" : "Snooze")
                            .font(.system(size: 30, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: vm.activeAlarm != nil)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 4) {
                        if snoozerEmoji.value {
                            Text(bgEmoji)
                                .font(.system(size: 128))
                                .minimumScaleFactor(0.5)
                        }

                        Text(context.date, format: Date.FormatStyle(date: .omitted, time: .shortened))
                            .font(.system(size: 70))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white)
                            .frame(height: 78)
                    }
                }
                Spacer()
            }
        }
    }

    private var bgEmoji: String {
        guard let bg = bg.value, !bgStale.value else {
            return "🤷"
        }

        if Localizer.getPreferredUnit() == .millimolesPerLiter, Localizer.removePeriodAndCommaForBadge(bgText.value) == "55" {
            return "🦄"
        }

        if Localizer.getPreferredUnit() == .milligramsPerDeciliter, bg == 100 {
            return "🦄"
        }

        switch bg {
        case ..<40: return "❌"
        case ..<55: return "🥶"
        case ..<73: return "😱"
        case ..<98: return "😊"
        case ..<102: return "🥇"
        case ..<109: return "😎"
        case ..<127: return "🥳"
        case ..<145: return "🤔"
        case ..<163: return "😳"
        case ..<181: return "😵‍💫"
        case ..<199: return "🎃"
        case ..<217: return "🙀"
        case ..<235: return "🔥"
        case ..<253: return "😬"
        case ..<271: return "😡"
        case ..<289: return "🤬"
        case ..<307: return "🥵"
        case ..<325: return "🫣"
        case ..<343: return "😩"
        case ..<361: return "🤯"
        default: return "👿"
        }
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

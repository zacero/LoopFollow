//
//  BLEDeviceSelectionView.swift
//  LoopFollow
//

import SwiftUI

struct BLEDeviceSelectionView: View {
    @ObservedObject var bleManager: BLEManager
    var selectedFilter: BackgroundRefreshType
    var onSelectDevice: (BLEDevice) -> Void

    var body: some View {
        VStack {
            List {
                if bleManager.devices.filter({ selectedFilter.matches($0) && !isSelected($0) }).isEmpty {
                    Text("No devices found yet. They'll appear here when discovered.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ForEach(bleManager.devices.filter { selectedFilter.matches($0) && !isSelected($0) }, id: \.id) { device in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name ?? "Unknown")

                                Text("RSSI: \(device.rssi) dBm")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectDevice(device)
                        }
                    }
                }
            }
        }
        .onAppear {
            bleManager.startScanning()
        }
        .onDisappear {
            bleManager.stopScanning()
        }
    }

    private func isSelected(_ device: BLEDevice) -> Bool {
        guard let selectedDevice = Storage.shared.selectedBLEDevice.value else {
            return false
        }
        return selectedDevice.id == device.id
    }
}

// MIDIInput — CoreMIDI hardware keyboard input (USB + Bluetooth). Native, so it
// works where Web-MIDI does not exist on iOS. Tracks held notes (with a short
// note-off debounce, like midi.ts) and reports the active pitch set + live
// note-on/off for sound. Bluetooth pairing is offered via a system sheet.

import Foundation
import Observation
import CoreMIDI
import CoreAudioKit
import SwiftUI

struct MIDIDeviceInfo: Identifiable, Equatable {
    let id: MIDIUniqueID
    let name: String
}

@MainActor
@Observable
final class MIDIInput {
    static let shared = MIDIInput()

    private(set) var devices: [MIDIDeviceInfo] = []
    private(set) var connected = false
    private(set) var activeNotes: Set<Int> = []

    /// Fired on every note-on (note, velocity) for live sound playback.
    var onNoteOn: ((Int, Int) -> Void)?
    /// Fired whenever the active-note set changes (for chord validation).
    var onNotesChanged: ((Set<Int>) -> Void)?

    private var client = MIDIClientRef()
    private var inPort = MIDIPortRef()
    private var started = false

    // note-off debounce (ms) so quick releases don't break chord validation
    private let debounce: TimeInterval = 0.03
    private var offWorkItems: [Int: DispatchWorkItem] = [:]

    private init() {}

    // MARK: Lifecycle

    func start() {
        guard !started else { refreshDevices(); return }
        started = true

        let name = "JazzChords" as CFString
        MIDIClientCreateWithBlock(name, &client) { [weak self] notification in
            // Device hot-plug — refresh on the main actor.
            Task { @MainActor in self?.refreshDevices() }
        }

        let portName = "JazzChords In" as CFString
        MIDIInputPortCreateWithProtocol(client, portName, ._1_0, &inPort) { [weak self] eventList, _ in
            self?.handle(eventList)
        }

        connectAllSources()
        refreshDevices()
    }

    private func connectAllSources() {
        let count = MIDIGetNumberOfSources()
        for i in 0..<count {
            let src = MIDIGetSource(i)
            if src != 0 { MIDIPortConnectSource(inPort, src, nil) }
        }
    }

    func refreshDevices() {
        var list: [MIDIDeviceInfo] = []
        let count = MIDIGetNumberOfSources()
        for i in 0..<count {
            let src = MIDIGetSource(i)
            var uid: MIDIUniqueID = 0
            MIDIObjectGetIntegerProperty(src, kMIDIPropertyUniqueID, &uid)
            var nameRef: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(src, kMIDIPropertyDisplayName, &nameRef)
            let name = (nameRef?.takeRetainedValue() as String?) ?? "MIDI \(i)"
            list.append(MIDIDeviceInfo(id: uid, name: name))
            MIDIPortConnectSource(inPort, src, nil) // ensure connected
        }
        devices = list
        connected = !list.isEmpty
    }

    func stop() {
        activeNotes = []
        onNotesChanged?(activeNotes)
        offWorkItems.values.forEach { $0.cancel() }
        offWorkItems.removeAll()
    }

    // MARK: Event parsing (MIDI 1.0 over UMP)

    private nonisolated func handle(_ eventList: UnsafePointer<MIDIEventList>) {
        // Collect (status, data1, data2) tuples off the realtime callback, then
        // hop to the main actor to mutate state.
        var messages: [(UInt8, UInt8, UInt8)] = []
        var packet = eventList.pointee.packet
        let numPackets = Int(eventList.pointee.numPackets)
        for _ in 0..<numPackets {
            let words = withUnsafeBytes(of: packet.words) { raw -> [UInt32] in
                let buf = raw.bindMemory(to: UInt32.self)
                return Array(buf.prefix(Int(packet.wordCount)))
            }
            for word in words {
                let messageType = (word >> 28) & 0xF
                // 0x2 = MIDI 1.0 channel voice message
                if messageType == 0x2 {
                    let status = UInt8((word >> 16) & 0xFF)
                    let data1 = UInt8((word >> 8) & 0xFF)
                    let data2 = UInt8(word & 0xFF)
                    messages.append((status, data1, data2))
                }
            }
            packet = MIDIEventPacketNext(&packet).pointee
        }
        if messages.isEmpty { return }
        Task { @MainActor [messages] in
            for m in messages { self.process(status: m.0, data1: m.1, data2: m.2) }
        }
    }

    private func process(status: UInt8, data1: UInt8, data2: UInt8) {
        let command = status & 0xF0
        let note = Int(data1)
        let velocity = Int(data2)

        if command == 0x90 && velocity > 0 {
            offWorkItems[note]?.cancel(); offWorkItems[note] = nil
            activeNotes.insert(note)
            onNoteOn?(note, velocity)
            onNotesChanged?(activeNotes)
        } else if command == 0x80 || (command == 0x90 && velocity == 0) {
            // debounce note-off for validation stability
            offWorkItems[note]?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.activeNotes.remove(note)
                self.offWorkItems[note] = nil
                self.onNotesChanged?(self.activeNotes)
            }
            offWorkItems[note] = work
            DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: work)
        }
    }
}

/// Bluetooth-MIDI pairing sheet (CoreAudioKit). Presented from Settings.
struct BluetoothMIDISheet: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        CABTMIDICentralViewController()
    }
    func updateUIViewController(_ vc: CABTMIDICentralViewController, context: Context) {}
}

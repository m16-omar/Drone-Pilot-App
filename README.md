# Drone Control Pilot

> Cross-Platform Ground Control Station (GCS) and Fleet Management Platform for DIY ESP32/Arduino Drones.  
> **Tech Stack:** Flutter (Riverpod + GoRouter) · Serverpod 4 (PostgreSQL) · Wi-Fi UDP · Python Simulator

---

## Quick Navigation

- 📖 **[Master Project & Architecture Guide](PROJECT_GUIDE.md)**: Full 13-section architectural specification, data schemas, safety rules, and setup instructions.
- 📡 **[UDP Protocol v1.0 Specification](docs/udp-protocol-v1.md)**: Packet formats, handshake definitions, telemetry schemas, and timeout invariants.
- 🚁 **[Python UDP Drone Simulator](tools/drone_simulator.py)**: Standalone tool to simulate an ESP32 drone locally for client testing.

---

## Key Architectural Decisions

- **Flutter**: Cross-platform Android and iOS pilot interface.
- **Riverpod**: Reactive state management and dependency injection.
- **GoRouter**: Declarative app navigation with offline route guards.
- **MVC**: Feature-first code organization (Model-View-Controller) inside each capability folder.
- **UDP + Protocol Adapter**: Direct, low-latency local Wi-Fi communication with the drone.
- **Serverpod + PostgreSQL**: Optional cloud functionality for fleet management, never required for basic flight control.
- **Simulated Drone**: Develop, profile, and test the full client and network stack without physical hardware first.

---

## Quickstart: Running the Local Simulator

### 1. Launch the Drone Simulator
```bash
python3 tools/drone_simulator.py
```
*Listens on `0.0.0.0:8765` for incoming UDP datagrams and broadcasts telemetry at 1 Hz once connected.*

### 2. Run the Flutter Pilot App
Ensure you are in the `app` directory:
```bash
cd app
```

Launch on your target device:
```bash
# On iOS Simulator (e.g. iPhone)
flutter run -d "iPhone 18 Pro"

# On macOS Desktop
flutter run -d macos

# On Web Browser
flutter run -d chrome
```

### 3. Run the Serverpod Cloud Backend
```bash
cd server
dart bin/main.dart
```

---

## Core System Architecture

```text
Flutter Pilot App (iOS / Android / macOS)
  │
  ├── [Direct Wi-Fi UDP (<= 1200 B, 10-50 Hz)] ──> ESP32 Flight Controller (Onboard PID & Failsafes)
  │
  └── [HTTPS / WebSockets (Cloud Sync)] ─────────> Serverpod 4 Backend + PostgreSQL (Missions & Fleet Logs)
```

For full system architecture, state machines, and code templates, see **[PROJECT_GUIDE.md](PROJECT_GUIDE.md)**.

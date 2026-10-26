# Drone Control Pilot — UDP Communication Protocol Specification (v1.0)

**Version:** 1.0.0  
**Transport:** UDP over Wi-Fi (Direct SoftAP or Shared Local WLAN)  
**Encoding:** UTF-8 JSON Datagrams  
**Default Port:** 8765 (Drone/Simulator Listener), 8766 (Flutter Client Listener)  
**Maximum Transmission Unit (MTU):** <= 1200 bytes (to prevent IP packet fragmentation)  

---

## 1. Protocol Architecture & Philosophy

The UDP Communication Protocol v1.0 is designed for low-latency, real-time command dispatch and telemetry exchange between the **Drone Control Pilot** mobile application (Flutter) and the **ESP32 Flight Controller** (or local simulator).

### Key Design Principles:
1. **Local-First & Direct:** Operates completely offline over direct Wi-Fi (SoftAP or local network) with zero dependency on internet access or the Serverpod cloud backend.
2. **Stateless Transport with State Machine Validation:** UDP packets are self-contained. The receiver validates sequence numbers, timestamps, and active state machine constraints.
3. **Fail-Safe by Default:** The flight controller runs a local watchdog (default 1000ms–3000ms). If control setpoints or heartbeats stop arriving, the firmware autonomously transitions to a configured failsafe (e.g., hover, controlled descent, or disarm).
4. **Inspectability:** Version 1.0 utilizes human-readable JSON datagrams for rapid prototyping, debugging, and packet inspection. A compact binary protocol (e.g., Protocol Buffers or packed C structs / CRTP) can be introduced in v2.0 once control loops are hardened.

---

## 2. Common Packet Header

Every packet transmitted between the mobile application and the drone must contain the following top-level keys:

| Field | Type | Description |
|---|---|---|
| `v` | integer | Protocol version number (must be `1`). |
| `type` | string | Identifier for the message type (e.g., `hello`, `telemetry`, `setpoint`). |
| `seq` | integer | Strictly increasing sequence number for freshness and packet drop tracking. |

Optional top-level fields:
- `client_id`: Unique client identifier string (e.g., `"pilot-mac-001"`).
- `device_id`: Drone hardware or simulator identifier (e.g., `"SIM-001"`, `"ESP32-DRONE-4A2F"`).
- `timestamp_ms`: Epoch timestamp in milliseconds.

---

## 3. Message Catalog

### 3.1 Handshake (`hello` / `hello_ack`)

Used to establish the link, exchange capabilities, and verify protocol compatibility.

#### App → Drone (`hello`)
```json
{
  "v": 1,
  "type": "hello",
  "seq": 1,
  "client_id": "pilot-dev-001"
}
```

#### Drone → App (`hello_ack`)
```json
{
  "v": 1,
  "type": "hello_ack",
  "seq": 1,
  "device_id": "SIM-001",
  "firmware": "simulator-1.0",
  "mode": "SIMULATION",
  "capabilities": [
    "telemetry",
    "arm_simulated",
    "mission_simulation"
  ]
}
```

---

### 3.2 Heartbeat & Link Quality (`ping` / `pong`)

Sent periodically (default: 1 Hz to 5 Hz) when no control setpoints are being transmitted to ensure link liveness and measure round-trip latency.

#### App → Drone (`ping`)
```json
{
  "v": 1,
  "type": "ping",
  "seq": 14,
  "timestamp_ms": 1793050123456
}
```

#### Drone → App (`pong`)
```json
{
  "v": 1,
  "type": "pong",
  "seq": 14,
  "device_id": "SIM-001",
  "echo_timestamp_ms": 1793050123456
}
```

---

### 3.3 Telemetry Broadcast (`telemetry`)

Broadcast by the drone at a fixed rate (default: 5 Hz to 20 Hz depending on link bandwidth and hardware capabilities).

#### Drone → App (`telemetry`)
```json
{
  "v": 1,
  "type": "telemetry",
  "seq": 145,
  "device_id": "SIM-001",
  "timestamp_ms": 1793050000000,
  "armed": false,
  "flight_mode": "MANUAL",
  "battery_percent": 94.5,
  "battery_voltage": 11.8,
  "roll_deg": 1.4,
  "pitch_deg": -0.8,
  "yaw_deg": 88.5,
  "altitude_m": 0.0,
  "speed_mps": 0.0,
  "gps_fix": false,
  "satellites": 0,
  "link_quality_percent": 100
}
```

---

### 3.4 State Transitions (`arm` / `disarm`)

Explicit state transition requests. The firmware performs pre-flight sensor and safety checks before granting an arm request.

#### App → Drone (`arm` or `arm_simulated`)
```json
{
  "v": 1,
  "type": "arm",
  "seq": 45,
  "force": false
}
```

#### Drone → App (`ack`)
```json
{
  "v": 1,
  "type": "ack",
  "seq": 45,
  "command": "arm",
  "accepted": true,
  "mode": "SIMULATION",
  "reason": ""
}
```

---

### 3.5 Real-Time Flight Control Setpoint (`control_setpoint`)

Sent continuously by the pilot app while manual controls (virtual joysticks or physical gamepads) are engaged. Frequency: 20 Hz – 50 Hz.

#### App → Drone (`control_setpoint`)
```json
{
  "v": 1,
  "type": "control_setpoint",
  "seq": 204,
  "roll": 0.0,
  "pitch": 0.0,
  "yaw": 0.0,
  "thrust": 0.35,
  "timestamp_ms": 1793050200000
}
```
*Note: Normalized values: `roll` [-1.0, 1.0], `pitch` [-1.0, 1.0], `yaw` [-1.0, 1.0], `thrust` [0.0, 1.0].*

---

### 3.6 Recovery & Safety Commands (`land` / `emergency_stop`)

#### App → Drone (`land`)
Initiates an autonomous controlled descent and auto-disarm upon touchdown.
```json
{
  "v": 1,
  "type": "land",
  "seq": 310
}
```

#### App → Drone (`emergency_stop`)
Immediate motor cutoff. Only to be used in catastrophic conditions.
```json
{
  "v": 1,
  "type": "emergency_stop",
  "seq": 999,
  "confirm": true
}
```

---

## 4. Timeout and Freshness Rules

1. **Stale Telemetry Watchdog (App side):** If no valid `telemetry` or `pong` packet is received within **3000 ms**, the Flutter UI must enter `Link Lost` state and alert the pilot visually and acoustically.
2. **Command Watchdog (Drone side):** If the drone is armed and in manual flight mode, and no `control_setpoint` or `ping` is received for **1500 ms**, the firmware enters failsafe mode (stabilize & descent).
3. **Packet Size Enforcement:** Any packet exceeding 1200 bytes must be discarded immediately without parsing to prevent buffer overflow vulnerabilities.

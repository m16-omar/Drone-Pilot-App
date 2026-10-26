#!/usr/bin/env python3
"""
Drone Control Pilot — Simulated Drone UDP Server
------------------------------------------------
Provides a local UDP server mimicking an ESP32 drone flight controller.
Implements the Drone Control Pilot UDP Protocol v1.0.

Usage:
    python3 tools/drone_simulator.py [--host 0.0.0.0] [--port 8765]
"""

import argparse
import asyncio
import json
import math
import sys
import time

DEFAULT_HOST = "0.0.0.0"
DEFAULT_PORT = 8765
MAX_PACKET_SIZE = 1200


class DroneSimulator(asyncio.DatagramProtocol):
    def __init__(self):
        self.transport = None
        self.clients = set()
        self.sequence = 0
        self.started_at = time.monotonic()
        self.is_armed = False
        self.altitude = 0.0
        self.thrust = 0.0

    def connection_made(self, transport):
        self.transport = transport
        sockname = transport.get_extra_info("sockname")
        print(f"[SIMULATOR] Drone simulator running on {sockname[0]}:{sockname[1]}")
        print("[SIMULATOR] Waiting for client connections (e.g. Flutter app)...")

    def datagram_received(self, data, addr):
        if len(data) > MAX_PACKET_SIZE:
            print(f"[SIMULATOR] Warning: Rejected oversized packet ({len(data)} bytes) from {addr}")
            return

        try:
            message = json.loads(data.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            print(f"[SIMULATOR] Warning: Rejected invalid JSON packet from {addr}")
            return

        if not isinstance(message, dict) or message.get("v") != 1:
            print(f"[SIMULATOR] Rejected incompatible packet version from {addr}: {message}")
            return

        message_type = message.get("type")
        seq = message.get("seq", 0)

        # Ensure the client is registered in our broadcast set
        if addr not in self.clients:
            self.clients.add(addr)
            print(f"[SIMULATOR] Registered client: {addr}")

        if message_type == "hello":
            client_id = message.get("client_id", "unknown")
            print(f"[SIMULATOR] Handshake received from client '{client_id}' at {addr}")
            self.send({
                "v": 1,
                "type": "hello_ack",
                "seq": seq,
                "device_id": "SIM-001",
                "firmware": "simulator-1.0",
                "mode": "SIMULATION",
                "capabilities": [
                    "telemetry",
                    "arm_simulated",
                    "mission_simulation",
                ],
            }, addr)

        elif message_type == "ping":
            self.send({
                "v": 1,
                "type": "pong",
                "seq": seq,
                "device_id": "SIM-001",
                "echo_timestamp_ms": message.get("timestamp_ms", int(time.time() * 1000)),
            }, addr)

        elif message_type in ("arm", "arm_simulated"):
            self.is_armed = True
            print(f"[SIMULATOR] Armed state set to TRUE by {addr}")
            self.send({
                "v": 1,
                "type": "ack",
                "seq": seq,
                "command": message_type,
                "accepted": True,
                "mode": "SIMULATION",
            }, addr)

        elif message_type in ("disarm", "disarm_simulated"):
            self.is_armed = False
            self.altitude = 0.0
            print(f"[SIMULATOR] Armed state set to FALSE by {addr}")
            self.send({
                "v": 1,
                "type": "ack",
                "seq": seq,
                "command": message_type,
                "accepted": True,
                "mode": "SIMULATION",
            }, addr)

        elif message_type == "control_setpoint":
            self.thrust = float(message.get("thrust", 0.0))
            if self.is_armed and self.thrust > 0.1:
                self.altitude = min(50.0, max(0.0, self.altitude + (self.thrust - 0.5) * 0.2))

        elif message_type == "land":
            print(f"[SIMULATOR] Automated landing triggered by {addr}")
            self.altitude = 0.0
            self.is_armed = False
            self.send({
                "v": 1,
                "type": "ack",
                "seq": seq,
                "command": "land",
                "accepted": True,
                "mode": "SIMULATION",
            }, addr)

        else:
            print(f"[SIMULATOR] Unhandled message type '{message_type}' from {addr}")

    def send(self, message, addr):
        payload = json.dumps(message, separators=(",", ":")).encode("utf-8")
        self.transport.sendto(payload, addr)

    def publish_telemetry(self):
        elapsed = time.monotonic() - self.started_at
        self.sequence += 1

        # Generate realistic gentle attitude oscillations
        roll = round(math.sin(elapsed * 0.8) * 2.5, 2)
        pitch = round(math.cos(elapsed * 0.6) * 1.8, 2)
        yaw = round((elapsed * 5.0) % 360.0, 1)
        battery = max(0.0, round(98.0 - elapsed * 0.02, 1))

        telemetry = {
            "v": 1,
            "type": "telemetry",
            "seq": self.sequence,
            "device_id": "SIM-001",
            "timestamp_ms": int(time.time() * 1000),
            "armed": self.is_armed,
            "battery_percent": battery,
            "roll_deg": roll,
            "pitch_deg": pitch,
            "yaw_deg": yaw,
            "altitude_m": round(self.altitude, 1),
            "speed_mps": round(1.2 if self.is_armed else 0.0, 1),
            "gps_fix": False,
            "link_quality_percent": 100,
        }

        # Send to all registered clients
        dead_clients = set()
        for client in list(self.clients):
            try:
                self.send(telemetry, client)
            except Exception as e:
                print(f"[SIMULATOR] Error sending telemetry to {client}: {e}")
                dead_clients.add(client)

        self.clients -= dead_clients

    async def run(self):
        while True:
            self.publish_telemetry()
            await asyncio.sleep(1.0)


async def main():
    parser = argparse.ArgumentParser(description="Drone Control Pilot UDP Simulator")
    parser.add_argument("--host", default=DEFAULT_HOST, help=f"Host address to bind (default: {DEFAULT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help=f"UDP port to bind (default: {DEFAULT_PORT})")
    args = parser.parse_args()

    loop = asyncio.get_running_loop()

    transport, protocol = await loop.create_datagram_endpoint(
        DroneSimulator,
        local_addr=(args.host, args.port),
    )

    try:
        await protocol.run()
    except asyncio.CancelledError:
        pass
    finally:
        transport.close()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[SIMULATOR] Simulator stopped by user.")
        sys.exit(0)

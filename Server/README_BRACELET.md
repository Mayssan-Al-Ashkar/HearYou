## HearYou Bracelet: Arduino + MongoDB bridge

This folder contains two parts:

- `ArduinoBracelet.ino`: firmware for the bracelet (Arduino UNO).
- `bracelet_bridge.py`: Python service that connects MongoDB <-> Arduino via Serial.

### Hardware wiring

- RGB LED (common cathode)
  - Red -> D9 (PWM)
  - Green -> D10 (PWM)
  - Blue -> D11 (PWM)
- Vibration motor -> D6 (PWM) through NPN transistor + diode + resistor (as in your breadboard)
- Push button -> D2 with the internal pull-up (wire the other side of the button to GND)

### Arduino Firmware

1) Open `ArduinoBracelet.ino` in Arduino IDE.
2) Select the correct board and port, then Upload.

The sketch:
- Accepts serial commands like `{"color":"green","vibrate":255}` or `{"off":1}`
- Reports button presses as `BTN:DOWN` / `BTN:UP` lines on Serial.

### Python Bridge

Install dependencies (Windows PowerShell):

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install pyserial pymongo requests
```

Set environment variables (adjust COM port and Mongo):

```powershell
$env:API_BASE = "http://127.0.0.1:5000"   # your backend that exposes POST /events/
$env:MONGO_URI = "mongodb://localhost:27017"
$env:MONGO_DB = "hearyou"
$env:BRACELET_COM = "COM3"                 # change to your Arduino COM
$env:BRACELET_BAUD = "9600"
$env:BRACELET_VIB_MS = "800"               # how long to vibrate per event
```

Run the bridge:

```powershell
python bracelet_bridge.py
```

What it does:
- Watches `settings` collection document `{ _id: "global" }` for color mapping and `vibration` on/off.
- Watches `events` collection for new inserts. When an event arrives, it:
  - Maps `title` to a color using `colors` in settings (e.g., `door_knocking: "yellow"`).
  - Sends `color` and `vibrate` (255 if vibration is true, 0 otherwise) to the Arduino.
  - Stops vibration after `BRACELET_VIB_MS` while keeping the color on.
- Listens to `BTN:DOWN` from the Arduino button and posts a new event:
  - `title = "door knocking"`, `source = "bracelet_button"` to `POST /events/` on `API_BASE`.

### Collections shape

- `settings` (single doc):
  ```json
  {
    "_id": "global",
    "colors": {
      "baby_crying": "green",
      "door_knocking": "yellow",
      "phone_call": "blue",
      "baby_movement": "red"
    },
    "vibration": true
  }
  ```

- `events` (inserts created by your backend and the bridge):
  ```json
  {
    "title": "baby crying",
    "description": "test",
    "isImportant": false,
    "eventAt": "2025-01-01T00:00:00Z",
    "createdAt": "2025-08-31T11:53:50.280Z",
    "source": "ml"
  }
  ```

> Note: The bridge uses MongoDB change streams when available. If the server/cluster doesn't support them, it falls back to polling.

### Troubleshooting

- If you don't see `READY` on serial after starting the bridge, make sure the correct `COM` is used and the Arduino sketch is uploaded.
- If colors look inverted, you might have a common-anode RGB LED; invert PWM values or rewire using common-cathode.
- If the motor stays on too long, lower `BRACELET_VIB_MS`.



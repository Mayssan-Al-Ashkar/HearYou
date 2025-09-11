// Arduino sketch for HearYou bracelet
// Pins
// RGB LED (common cathode): R=9, G=10, B=11
// Vibration motor via NPN transistor: PWM=6
// Push button (active low with pullup): D2

const int PIN_RED = 9;
const int PIN_GREEN = 10;
const int PIN_BLUE = 11;
const int PIN_MOTOR = 6;
const int PIN_BUTTON = 2;

// Debounce
unsigned long lastButtonChangeMs = 0;
int lastButtonState = HIGH; // using INPUT_PULLUP
bool reportedDown = false;

// Helpers
void setRgb(uint8_t r, uint8_t g, uint8_t b) {
  analogWrite(PIN_RED, r);
  analogWrite(PIN_GREEN, g);
  analogWrite(PIN_BLUE, b);
}

void setMotor(uint8_t intensity) {
  analogWrite(PIN_MOTOR, intensity);
}

void clearAll() {
  setRgb(0, 0, 0);
  setMotor(0);
}

// Expect commands over Serial (9600 baud) in single-line JSON-like form:
// CMD examples:
//   {"color":"red","vibrate":1}
//   {"color":"#RRGGBB","vibrate":0}
//   {"off":1}
// Color names supported: red, green, blue, yellow, cyan, magenta, white, off

void parseColorName(const String &name, uint8_t &r, uint8_t &g, uint8_t &b) {
  String n = name; n.toLowerCase();
  if (n == "red") { r=255; g=0; b=0; return; }
  if (n == "green") { r=0; g=255; b=0; return; }
  if (n == "blue") { r=0; g=0; b=255; return; }
  if (n == "yellow") { r=255; g=255; b=0; return; }
  if (n == "cyan") { r=0; g=255; b=255; return; }
  if (n == "magenta") { r=255; g=0; b=255; return; }
  if (n == "white") { r=255; g=255; b=255; return; }
  // off or unknown
  r=0; g=0; b=0;
}

void parseHexColor(const String &hex, uint8_t &r, uint8_t &g, uint8_t &b) {
  // Expect #RRGGBB
  if (hex.length() == 7 && hex[0] == '#') {
    long value = strtol(hex.substring(1).c_str(), NULL, 16);
    r = (value >> 16) & 0xFF;
    g = (value >> 8) & 0xFF;
    b = value & 0xFF;
    return;
  }
  r=0; g=0; b=0;
}

void applyCommand(const String &line) {
  String s = line;
  s.trim();
  if (s.length() == 0) return;
  if (s.indexOf("\"off\"") >= 0) {
    clearAll();
    Serial.println(F("ACK"));
    return;
  }

  // Find color value
  uint8_t rr=0, gg=0, bb=0;
  int colorIdx = s.indexOf("\"color\"");
  if (colorIdx >= 0) {
    int colon = s.indexOf(':', colorIdx);
    int q1 = s.indexOf('"', colon + 1);
    int q2 = s.indexOf('"', q1 + 1);
    if (q1 >= 0 && q2 > q1) {
      String colorVal = s.substring(q1 + 1, q2);
      if (colorVal.startsWith("#")) parseHexColor(colorVal, rr, gg, bb);
      else parseColorName(colorVal, rr, gg, bb);
    }
  }

  // Find vibrate value (0/1 or 0-255)
  uint8_t vib = 0;
  int vibIdx = s.indexOf("\"vibrate\"");
  if (vibIdx >= 0) {
    int colon = s.indexOf(':', vibIdx);
    if (colon > 0) {
      long val = s.substring(colon + 1).toInt();
      if (val < 0) val = 0; if (val > 255) val = 255;
      vib = (uint8_t)val;
    }
  }

  setRgb(rr, gg, bb);
  setMotor(vib);
  Serial.println(F("ACK"));
}

void setup() {
  pinMode(PIN_RED, OUTPUT);
  pinMode(PIN_GREEN, OUTPUT);
  pinMode(PIN_BLUE, OUTPUT);
  pinMode(PIN_MOTOR, OUTPUT);
  pinMode(PIN_BUTTON, INPUT_PULLUP);
  clearAll();

  Serial.begin(9600);
  while (!Serial) { ; }
  Serial.println(F("READY"));
}

void loop() {
  // 1) Read serial lines
  static String line = "";
  while (Serial.available() > 0) {
    char ch = (char)Serial.read();
    if (ch == '\n' || ch == '\r') {
      if (line.length() > 0) {
        applyCommand(line);
        line = "";
      }
    } else {
      line += ch;
      if (line.length() > 200) line = ""; // safety
    }
  }

  // 2) Report button state (edge on press)
  int s = digitalRead(PIN_BUTTON);
  unsigned long now = millis();
  if (s != lastButtonState) {
    lastButtonChangeMs = now;
    lastButtonState = s;
  }
  if ((now - lastButtonChangeMs) > 30) { // debounce 30ms
    if (s == LOW && !reportedDown) {
      Serial.println(F("BTN:DOWN"));
      reportedDown = true;
    }
    if (s == HIGH && reportedDown) {
      Serial.println(F("BTN:UP"));
      reportedDown = false;
    }
  }
}



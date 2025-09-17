// Pins
const int PIN_RED = 9;
const int PIN_GREEN = 10;
const int PIN_BLUE = 11;
const int PIN_MOTOR = 6;
const int PIN_BUTTON = 2;
// Debounce
unsigned long lastButtonChangeMs = 0;
int lastButtonState = HIGH;
bool reportedDown = false;
// Define Rgb BEFORE any functions that use it
struct Rgb { uint8_t r; uint8_t g; uint8_t b; };
void setRgb(uint8_t r, uint8_t g, uint8_t b) {
  analogWrite(PIN_RED, r);
  analogWrite(PIN_GREEN, g);
  analogWrite(PIN_BLUE, b);
}
void setMotor(uint8_t intensity) { analogWrite(PIN_MOTOR, intensity); }
void clearAll() { setRgb(0,0,0); setMotor(0); }
Rgb parseColorName(const String &name) {
  String n = name; n.toLowerCase();
  if (n == "red") return {255,0,0};
  if (n == "green") return {0,255,0};
  if (n == "blue") return {0,0,255};
  if (n == "yellow") return {255,255,0};
  if (n == "cyan") return {0,255,255};
  if (n == "magenta") return {255,0,255};
  if (n == "white") return {255,255,255};
  if (n == "off") return {0,0,0};
  return {0,0,0};
}
Rgb parseHexColor(const String &hex) {
  if (hex.length() == 7 && hex[0] == '#') {
    long v = strtol(hex.substring(1).c_str(), NULL, 16);
    return {(uint8_t)((v>>16)&0xFF),(uint8_t)((v>>8)&0xFF),(uint8_t)(v&0xFF)};
  }
  return {0,0,0};
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
  Rgb rgb = {0, 0, 0};
  int colorIdx = s.indexOf("\"color\"");
  if (colorIdx >= 0) {
    int colon = s.indexOf(':', colorIdx);
    int q1 = s.indexOf('"', colon + 1);
    int q2 = s.indexOf('"', q1 + 1);
    if (q1 >= 0 && q2 > q1) {
      String colorVal = s.substring(q1 + 1, q2);
      if (colorVal.startsWith("#")) rgb = parseHexColor(colorVal);
      else rgb = parseColorName(colorVal);
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
  setRgb(rgb.r, rgb.g, rgb.b);
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
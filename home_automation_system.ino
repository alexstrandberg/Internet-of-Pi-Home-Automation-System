/*  Internet of Pi: Raspberry Pi-powered Home Automation System
    Author: Alex Strandberg
    December 28, 2016

    The system uses a Raspberry Pi and an Arduino Mega, along with other components
    to control appliances in a room and act as an alarm clock.

    Four PowerSwitch Tails turn appliances in a room on or off.
    The signals to control the PowerSwitch Tails are sent over 3.5mm audio cables.
    The appliances are turned on or off manually or based on a schedule or external sensors.
    For example, when the room is too warm, a fan can be configured to turn on.
    When a person enters the room, a light can be configured turn on.
    The RGB LED Matrix shuts off when the room is dark.
    A reed switch and foot switch notify when a door is opened and when a person leaves the room, respectively.
    A Pimoroni Display-o-Tron HAT connected to the Raspberry Pi allows the user to manually control appliances and interact with the system.
    The system acts as an alarm clock by playing music at a scheduled time to wake up the user.

    SERIAL COMMUNICATION PROTOCOL: 9600 baud
         $command!num_params@parameters,separated,by,commas*CRC
          - num_params and CRC are HEX values
          - Protocol is based on MTK NMEA protocol: http://www.hhhh.org/wiml/proj/nmeaxor.html
          - Arduino implementation of the protocol adapted from: http://elimelecsarduinoprojects.blogspot.com/2013/07/nmea-checksum-calculator.html

    Parts Used:
    - Raspberry Pi 2 Model B
    - Pimoroni Display-o-Tron HAT (https://www.adafruit.com/products/2694)
    - Arduino Mega
    - Mega protoshield for Arduino (https://www.adafruit.com/products/192)
    - 64x32 RGB LED Matrix (https://www.adafruit.com/products/2278)
    - Powerswitch tail 2 (x4) (https://www.adafruit.com/products/268)
    - ChronoDot - Ultra-precise Real Time Clock (https://www.adafruit.com/products/255)
    - Adafruit PT100 RTD Temperature Sensor Amplifier - MAX31865 (https://www.adafruit.com/products/3328)
    - PT100 RTD Temperature Sensor - 3 Wire
    - Adafruit Sensiron SHT31-D Temperature & Humidity Sensor Breakout (https://www.adafruit.com/products/2857)
    - Adafruit TSL2591 High Dynamic Range Digital Light Sensor (https://www.adafruit.com/products/1980)
    - 5V 10A switching power supply (https://www.adafruit.com/products/658)
    - Stereo 3.7W Class D Audio Amplifier - MAX98306 (https://www.adafruit.com/products/987)
    - Speaker - 3" Diameter - 4 Ohm 3 Watt (x2) (https://www.adafruit.com/products/1314)
    - Right-Angle 3.5mm Stereo Plug to Pigtail Cable (https://www.adafruit.com/products/1700)
    - 4-Way 2.1mm DC Barrel Jack Splitter Squid (https://www.adafruit.com/products/1352)
    - USB A Jack to 5.5/2.1mm jack adapter (x2) (https://www.adafruit.com/products/988)
    - USB cable - 6" A/MicroB (https://www.adafruit.com/products/898)
    - Magnetic contact switch (door sensor) (https://www.adafruit.com/products/375)
    - Foot switch (https://www.adafruit.com/products/423)
    - Female DC Power adapter - 2.1mm jack to screw terminal block (x2) (https://www.adafruit.com/products/368)
    - USB to 2.1mm Male Barrel Jack Cable (https://www.adafruit.com/products/2697)
    - 3.5mm (1/8") Stereo Audio Jack Terminal Block (x6)
    - 10ft 3.5mm Male-to-Male Audio Cables (x3)
    - USB Cable - Standard A-B

    Wiring:
    - Follows Adafruit tutorial for Arduino Mega Protoshield and 64x32 RGB LED Matrix: (https://learn.adafruit.com/32x16-32x32-rgb-led-matrix/connecting-using-a-proto-shield)
    - 3.5mm (1/8") Stereo Audio Jack Terminal Blocks are used to extend the length of the connections to the reed switch, foot switch, and Powerswitch tails
    - Reed Switch: One of the wires connects to Pin 30, the other to ground
    - Foot switch: The Normally Open wire connects to Pin 31, the Common wire to ground
    - Powerswitch tails: The +in pin on each connects to Pins 32, 33, 34, 35. The -in pin on each connects to ground
    - PT100 RTD Temperature Sensor Amplifier - MAX31865: Connects using Hardware SPI pins (50-53)
    - SHT31-D & TSL2591 - Connects using I2C pins
    - Chronodot: The following pins connect to the respective Arduino pins: VCC (5V), GND, SDA, SCL
    - Stereo 3.7W Class D Audio Amplifier - MAX98306: The 3.5mm pigtail cable's wires are connected to L-/R- (soldered together), L+, R+. The speakers' + and - wires are connected to the respective amplifier outputs. VDD and GND are connected to a 2.1mm jack to screw terminal block (powered by Pi)
    - 5V 10A power supply: 2-Way 2.1mm DC Barrel Jack Splitter Squid connects power output to a 2.1mm jack to screw terminal block for the RGB Matrix power, USB to 2.1mm Male Barrel Jack Cable for the Pi Power (Micro-USB cable), and a 2.1mm jack to screw terminal block for the speaker amplifier.
    - The Raspberry Pi powers the Arduino and communicates through a standard A-B USB cable.

    External Libraries Used:
     - Arduino-DS3231 (https://github.com/jarzebski/Arduino-DS3231/)
     - RGB-matrix-Panel (https://github.com/adafruit/RGB-matrix-Panel)
     - Adafruit_SHT31 (https://github.com/adafruit/Adafruit_SHT31)
     - Adafruit_TSL2591 (https://github.com/adafruit/Adafruit_TSL2591_Library)
     - Adafruit_MAX31865 (https://github.com/adafruit/Adafruit_MAX31865)
*/

#include <Wire.h>
#include "EEPROM.h"
#include <DS3231.h>
#include <Adafruit_GFX.h>     // Core graphics library
#include <RGBmatrixPanel.h>   // Hardware-specific library
#include <Adafruit_Sensor.h>  // Core sensor library
#include "Adafruit_TSL2591.h" // Hardware-specific library
#include "Adafruit_SHT31.h"
#include <Adafruit_MAX31865.h>
#include <TimerThree.h>

// RGB Matrix Pin Connections
#define OE   9
#define LAT 10
#define CLK 11
#define A   A0
#define B   A1
#define C   A2
#define D   A3

// RGB Matrix Constants
#define TEXT_SIZE 8 // Multiple of 8
#define TEXT_WIDTH 5
#define TEXT_V_SPACING 4
#define TEXT_H_SPACING 1
#define TEXT_LEFT_OFFSET 8 // For top two rows only
#define BOTTOM_LEFT_OFFSET 2
#define TEMP_CURSOR_X BOTTOM_LEFT_OFFSET + 3*TEXT_WIDTH + 3*TEXT_H_SPACING
#define HUM_CURSOR_X BOTTOM_LEFT_OFFSET + 7*TEXT_WIDTH + 7*TEXT_H_SPACING
#define TOP_CURSOR_Y 0
#define MIDDLE_CURSOR_Y TEXT_SIZE + TEXT_V_SPACING
#define BOTTOM_CURSOR_Y 2*TEXT_SIZE + 2*TEXT_V_SPACING
#define COLON_OFFSET 2

RGBmatrixPanel matrix(A, B, C, D, CLK, LAT, OE, false, 64);

DS3231 clock;
RTCDateTime screen_dt = {1970, 1, 1, 0, 0, 0, 4, 0}; // Initial screen date/time information - inaccurate until info is read from RTC
RTCDateTime new_dt; // Date/Time information from the RTC

// Light and Temperature/Humidity sensors
Adafruit_TSL2591 tsl = Adafruit_TSL2591(2591); // pass in a number for the sensor identifier (for your use later)
Adafruit_SHT31 sht31 = Adafruit_SHT31();

Adafruit_MAX31865 max = Adafruit_MAX31865(53);

// The value of the Rref resistor. Use 430.0!
#define RREF 430.0

// Sensor/Powerswitch tail pins
#define REED_SWITCH_PIN 30
#define FOOT_SWITCH_PIN 31
#define NUM_APPLIANCES 4
byte APPLIANCE_PINS[NUM_APPLIANCES] = {32, 33, 34, 35};

volatile boolean newMatrixPrint = true; // True if the date, time, and other info need to be printed on the RGB matrix

// Configuration parameters that are loaded in from EEPROM
boolean use12HourFormat = false;
boolean useFahrenheit = false;
byte lightThreshold = 256;

// Color constants for matrix output
uint16_t eraseColor = matrix.Color333(0,0,0);     // Black
uint16_t hourColor = matrix.Color333(7,0,0);      // Red
uint16_t colonColor = matrix.Color333(4,1,1);     // Light Red
uint16_t minuteColor = matrix.Color333(7,7,0);    // Yellow
uint16_t amColor = matrix.Color333(0,7,0);        // Green
uint16_t monthColor = matrix.Color333(0,7,7);     // Teal
uint16_t dayColor = matrix.Color333(0,0,7);       // Blue
uint16_t yearColor = matrix.Color333(7,0,4);      // Pink
uint16_t dayOfWeekColor = matrix.Color333(3,0,5); // Purple
uint16_t tempColor = matrix.Color333(7,7,7);      // White
uint16_t humColor = matrix.Color333(7,3,0);       // Orange

volatile boolean colonVisible = true;  // True if the colon is visible on the matrix

// These variables store the latest sensor data and the sensor data on the matrix
byte screenTemp = 0;
byte screenHum = 0;

byte newTemp = 0;
byte newHum = 0;

byte currentMinuteCursorX = TEXT_LEFT_OFFSET + 4*TEXT_WIDTH + 4*TEXT_H_SPACING; // Stores the cursor position of where the minutes are displayed
byte currentDayCursorX = TEXT_LEFT_OFFSET + 4*TEXT_WIDTH + 4*TEXT_H_SPACING; // Stores the cursor position of where the day is displayed

volatile boolean matrixEnabled = true; // True if the matrix is actively displaying info

// Variables used for serial communication
const byte serBuffLen = 80;
char serBuffer[serBuffLen];
byte serIndex = 0;
byte serStart = 0;
byte serEnd = 0;
byte serCRC = 0;
boolean serDataEnd = false;

// EEPROM Storage Address List
const byte addrUse12HourFormat = 0;
const byte addrUseFahrenheit = addrUse12HourFormat + 1;
const byte addrLightThreshold = addrUse12HourFormat + 2;

boolean footSwitchPressed = false; // True if the foot switch is pressed (low signal)
boolean doorOpen = false; // True if the door is open (Reed switch reads high signal

String lightSensorMode = "CLEAR_WHEN_DARK"; // How the light sensor data is used - CLEAR_WHEN_DARK (default, normal operation) clears the matrix only when the light level is below the threshold
                                            // DISABLE_WHEN_DARK clears and disables the matrix from displaying info again once the light level is below the threshold (for nighttime)
                                            // IGNORE keeps the matrix displaying info regardless of light levels (when an alarm goes off)

const int lightSensorMaxVisibleValue = 9999; // If the calculation of the amount of visible light exceeds this number, then there is actually no visible light

void setup() {
  Serial.begin(9600); // Initialize the serial port
  clock.begin();
  matrix.begin();
  
  //clock.setDateTime(__DATE__, __TIME__); // Set date/time to compile date/time

  matrix.setTextSize(TEXT_SIZE / 8);     // size 1 == 8 pixels high
  matrix.setTextWrap(false); // Don't wrap at end of line

  tsl.begin();       // Initialize the sensors
  sht31.begin(0x44);
  max.begin(MAX31865_3WIRE);

  pinMode(REED_SWITCH_PIN, INPUT_PULLUP); // Enable internal pullups for Reed Switch and Foot Switches
  pinMode(FOOT_SWITCH_PIN, INPUT_PULLUP);

  for (int i = 0; i < (sizeof(APPLIANCE_PINS)/sizeof(APPLIANCE_PINS[0])); i++) { // Set the appliance pins to outputs
    pinMode(APPLIANCE_PINS[i], OUTPUT);
  }

  // Load configuration parameters from EEPROM into program memory
  if (EEPROM.read(addrUse12HourFormat) == B1) use12HourFormat = true;
  if (EEPROM.read(addrUseFahrenheit) == B1) useFahrenheit = true;
  lightThreshold = EEPROM.read(addrLightThreshold);

  Timer3.initialize(1000000); // Have the colon blink every 1 second
  Timer3.attachInterrupt(colonBlink);
}

void loop() {
  // Retrieve the latest temperature and humidity sensor data
  
  newTemp = useFahrenheit ? (int) (max.temperature(100, RREF) * 1.8000 + 32.50) : (int) (max.temperature(100, RREF) + 0.5); // Adding 0.5 to either result to round to 0 decimal places
  newHum = (int) (sht31.readHumidity() + 0.5);

  // Retrieve the latest light sensor data - (full-ir) is the amount of visible light
  uint32_t lum = tsl.getFullLuminosity();
  uint16_t ir, full;
  ir = lum >> 16;
  full = lum & 0xFFFF;
  int visible = full - ir < lightSensorMaxVisibleValue ? full - ir : 0;
  if (visible < lightThreshold && lightSensorMode != "IGNORE") {
    if (!newMatrixPrint) {
      newMatrixPrint = true;
      matrix.fillScreen(0);
    }
    if (lightSensorMode == "DISABLE_WHEN_DARK" && matrixEnabled) matrixEnabled = false;
  } else if (matrixEnabled) { // Update the matrix display if the matrix is enabled
    new_dt = clock.getDateTime();
    printTimeLineIfNeeded();
    printDateLineIfNeeded();
    printBottomLineIfNeeded();
  
    screen_dt = new_dt;
  }

  byte footSwitchStatus = digitalRead(FOOT_SWITCH_PIN);
  if (footSwitchStatus == LOW && !footSwitchPressed) {
    footSwitchPressed = true;
  } else if (footSwitchStatus == HIGH && footSwitchPressed) {
    footSwitchPressed = false;
  }
  
  byte doorStatus = digitalRead(REED_SWITCH_PIN);
  if (doorStatus == LOW && doorOpen) {
    doorOpen = false;
  } else if (doorStatus == HIGH && !doorOpen) {
    doorOpen = true;
  }

  // Handle new serial communication
  while (Serial.available() > 0) {
    char inChar = Serial.read();
    serBuffer[serIndex] = inChar;
    if (inChar == '$') serStart = serIndex; // Check for start and end characters
    else if (inChar == '*') serEnd = serIndex;

    serIndex++;
    if (inChar == '\n' || inChar == '\r') {
      serIndex = 0;
      serDataEnd = true;
    }
    
    if (serDataEnd) { // Process serial data if finished
      if (serEnd > serStart) {
        for (byte i = serStart+1; i < serEnd; i++) { // XOR every character in between '$' and '*'
          serCRC ^= serBuffer[i];
        }
  
        String receivedCRCString = "";
        for (byte j = serEnd+1; j < serBuffLen; j++ ) {
          if (serBuffer[j] == '\n') break;
          receivedCRCString += serBuffer[j];
        }
        byte receivedCRC = strtoul(receivedCRCString.c_str(), NULL, 16); // The CRC sent over serial - will be compared to calculated CRC to ensure valid message
        
        if (serCRC == receivedCRC) { // Verify that the calculated checksum matches the checksum sent over serial
          String data = "";
          for (int k = serStart+1; k < serEnd; k++) {
            data += (char)serBuffer[k];
          }

          // Parse command, numParams strings from serial
          String commandString = data.substring(0, data.indexOf('!'));
          String numParamsString = data.substring(data.indexOf('!')+1, data.indexOf('@'));
          if (strlen(commandString.c_str()) > 0 && strlen(numParamsString.c_str()) > 0) { // Make sure strings are not empty
            byte numParams = strtoul(numParamsString.c_str(), NULL, 16);
            String dataArray[numParams]; // Array of parameters - the data for a particular command
            byte startingIndex = data.indexOf('@') + 1;
            for (int x = 0; x < numParams; x++) {
              byte endingIndex = data.indexOf(',', startingIndex);
              dataArray[x] = data.substring(startingIndex, endingIndex);
              startingIndex = endingIndex+1;
            }

            if (commandString == "APP" && numParams == NUM_APPLIANCES) { // Command to turn appliances on or off - needs a 1 or a 0 for each appliance (on/off)
              for (int z = 0; z < NUM_APPLIANCES; z++) {
                if (dataArray[z] == "1") digitalWrite(APPLIANCE_PINS[z], HIGH); // Precaution: A "1" must be received in order to turn an appliance on
                else digitalWrite(APPLIANCE_PINS[z], LOW);                      // Otherwise, the appliance is turned off to be safe
              }
              sendOKMessage(commandString);
            } else if (commandString == "SET_DATE_TIME" && numParams == 6) { // Command to update the RTC date/time - needs year, month, day, hour, minutes, seconds
              int year = strtoul(dataArray[0].c_str(), NULL, 10);
              byte month = strtoul(dataArray[1].c_str(), NULL, 10);
              byte day = strtoul(dataArray[2].c_str(), NULL, 10);
              byte hour = strtoul(dataArray[3].c_str(), NULL, 10);
              byte minute = strtoul(dataArray[4].c_str(), NULL, 10);
              byte second = strtoul(dataArray[5].c_str(), NULL, 10);
              clock.setDateTime(year, month, day, hour, minute, second);
              clearMatrix();
              sendOKMessage(commandString);
            } else if (commandString == "SET_FORMATTING" && numParams == 2) { // Command to update the stored format preferences - 12 hour format, Fahrenheit
              if (dataArray[0] == "1") { // A "1" means that the preference should be true
                use12HourFormat = true;
                EEPROM.write(addrUse12HourFormat, 1);
              } else {
                use12HourFormat = false;
                EEPROM.write(addrUse12HourFormat, 0);
              }

              if (dataArray[1] == "1") {
                useFahrenheit = true;
                EEPROM.write(addrUseFahrenheit, 1);
              } else {
                useFahrenheit = false;
                EEPROM.write(addrUseFahrenheit, 0);
              }

              clearMatrix();
              sendOKMessage(commandString);
            } else if (commandString == "SET_LIGHT_THRESHOLD" && numParams == 1) { // Command to update the light threshold (can be between 0 and 255)
              lightThreshold = strtoul(dataArray[0].c_str(), NULL, 16);
              EEPROM.write(addrLightThreshold, lightThreshold);
              sendOKMessage(commandString);
            } else if (commandString == "ENABLE_MATRIX" && numParams == 1) { // Command to enable the matrix (turn the matrix on) and change the lightSensorMode
              matrixEnabled = true;
              lightSensorMode = dataArray[0];
              sendOKMessage(commandString);
            } else if (commandString == "DISABLE_MATRIX" && numParams == 0) { // Command to disable the matrix (turn the matrix off)
              matrixEnabled = false;
              clearMatrix();
              sendOKMessage(commandString);
            } else if (commandString == "GET_STATUS" && numParams == 0) { // Command to request the status of the system - Reed Switch, Foot Switch, Celsius temp, humidity, visible light, appliance states, date/time as a UNIX timestamp
              byte numParams = 6 + NUM_APPLIANCES;
              char tempString[6];
              char humString[6];
              dtostrf(max.temperature(100, RREF), 3, 2, tempString);
              dtostrf(sht31.readHumidity(), 3, 2, humString);
              String message = "STATUS!" + String(numParams) + '@';
              message += String(digitalRead(REED_SWITCH_PIN)) + ',';
              message += String(digitalRead(FOOT_SWITCH_PIN)) + ',';
              message += String(tempString) + ',';
              message += String(humString) + ',' + String(visible);
              for (int k = 0; k < NUM_APPLIANCES; k++) {
                message += ',' + String(digitalRead(APPLIANCE_PINS[k]));
              }
              message += ',' + String(clock.dateFormat("U", new_dt));
              sendSerialMessage(message);
            } else if (commandString == "GET_SENSOR" && numParams == 0) {
              byte numParams = 5;
              char tempString[6];
              char humString[6];
              dtostrf(max.temperature(100, RREF), 3, 2, tempString);
              dtostrf(sht31.readHumidity(), 3, 2, humString);
              String message = "SENSOR!" + String(numParams) + '@';
              message += String(tempString) + ',';
              message += String(humString) + ',' + String(visible) + ',';
              if (doorOpen) message += "OPENED,";
              else message += "CLOSED,";
              if (footSwitchPressed) message += "PRESSED";
              else message += "RELEASED";
              sendSerialMessage(message);
            } else sendErrorMessage("Bad command or data.");
          } else sendErrorMessage("Command or size was not sent.");
        } else sendErrorMessage("Checksum mismatch.");
      } else sendErrorMessage("Bad message.");

      // Set serial variables back to defaults after communication is finished
      serCRC = 0;
      serStart = 0;
      serEnd = 0;
      serDataEnd = false;
    }
  }
}

// Helper methods to put the cursor in the proper place for each line of the matrix
void setMatrixToTimeCursorPosition() {
  // 24 Hour Format is aligned more towards the center (No AM/PM means fewer characters to display)
  // 12 Hour Format lines up with the date (both offset by TEXT_LEFT_OFFSET)
  if (use12HourFormat) matrix.setCursor(TEXT_LEFT_OFFSET, 0);
  else matrix.setCursor(TEXT_LEFT_OFFSET + 2*TEXT_WIDTH + 2*TEXT_H_SPACING, 0);
}

void setMatrixToDateCursorPosition() {
  matrix.setCursor(TEXT_LEFT_OFFSET, MIDDLE_CURSOR_Y);
}

void setMatrixToBottomCursorPosition() {
  matrix.setCursor(BOTTOM_LEFT_OFFSET, BOTTOM_CURSOR_Y);
}

// Helper method to clear the matrix display
void clearMatrix() {
  newMatrixPrint = true; // When the matrix is enabled again, this will ensure that all info is drawn on the matrix
  matrix.fillScreen(0);
}

// Helper methods for serial communication
void sendErrorMessage(String error) {
  sendSerialMessage("ERROR!1@"+error);
}

void sendOKMessage(String lastCommand) {
  sendSerialMessage("OK!1@"+lastCommand);
}

void sendSerialMessage(String message) {
  byte CRC = 0;
  
  for (int j = 0; j < strlen(message.c_str()); j++) {
    CRC ^= message.charAt(j);
  }

  Serial.print('$');
  Serial.print(message);
  Serial.print('*');
  Serial.println(CRC, HEX);
}

// Methods that handle matrix output - they only erase what changes on the matrix while putting new info on the matrix
// After setting the matrix to the "erase" color (black), the methods print the old, outdated information on the matrix
// to clear that part of the matrix. Then, the text color is changed, and new information is drawn on the matrix in the
// proper locations.
void colonBlink() {
  if (matrixEnabled && !newMatrixPrint) {
    int cursor_x = TEXT_LEFT_OFFSET;
    if (!use12HourFormat) cursor_x = TEXT_LEFT_OFFSET + 2*TEXT_WIDTH + 2*TEXT_H_SPACING;
    int cursor_y = 0;
  
    // Tells where the colon needs to go (depends on whether the hour has one or two digits)
    int hour_offset = use12HourFormat ? strlen(clock.dateFormat("g", screen_dt)): strlen(clock.dateFormat("G", screen_dt));
    
    // Toggle displaying the colon or not - visible/invisible for equal amounts of time; if the hour changes, then the colon disappears during the update
    if (!colonVisible && new_dt.hour == screen_dt.hour) {
      matrix.fillRect(COLON_OFFSET + cursor_x + (TEXT_WIDTH + TEXT_H_SPACING) * hour_offset, cursor_y + 1, 2, 2, colonColor);
      matrix.fillRect(COLON_OFFSET + cursor_x + (TEXT_WIDTH + TEXT_H_SPACING) * hour_offset, cursor_y + 4, 2, 2, colonColor);
    } else {
      matrix.fillRect(COLON_OFFSET + cursor_x + (TEXT_WIDTH + TEXT_H_SPACING) * hour_offset, cursor_y + 1, 2, 2, eraseColor);
      matrix.fillRect(COLON_OFFSET + cursor_x + (TEXT_WIDTH + TEXT_H_SPACING) * hour_offset, cursor_y + 4, 2, 2, eraseColor);
    }
    colonVisible = !colonVisible;
  }
}

void printTimeLineIfNeeded() {
  matrix.setTextColor(eraseColor);
  setMatrixToTimeCursorPosition();

  // Variables that store where the hour is printed
  byte cursor_x = matrix.getCursorX();
  byte cursor_y = matrix.getCursorY();

  // Tells where the colon needs to go (depends on whether the hour has one or two digits)
  int hour_offset = use12HourFormat ? strlen(clock.dateFormat("g", screen_dt)): strlen(clock.dateFormat("G", screen_dt));

  if (new_dt.hour != screen_dt.hour && colonVisible) {
    matrix.fillRect(COLON_OFFSET + cursor_x + (TEXT_WIDTH + TEXT_H_SPACING) * hour_offset, cursor_y + 1, 2, 2, eraseColor);
    matrix.fillRect(COLON_OFFSET + cursor_x + (TEXT_WIDTH + TEXT_H_SPACING) * hour_offset, cursor_y + 4, 2, 2, eraseColor);
    colonVisible = false;
  }

  if (newMatrixPrint) { // If the screen is blank, then the proper location of the minutes needs to be determined
    if (hour_offset == 2) currentMinuteCursorX = cursor_x + 3*TEXT_WIDTH + 3*TEXT_H_SPACING;
    else currentMinuteCursorX = cursor_x + 2*TEXT_WIDTH + 2*TEXT_H_SPACING;
  }

  if (new_dt.minute != screen_dt.minute || newMatrixPrint) { // Top row of the matrix needs to be updated if the minute has changed
    String new_hour = use12HourFormat ? clock.dateFormat("g", new_dt) : clock.dateFormat("G", new_dt);
    if (new_dt.hour != screen_dt.hour || newMatrixPrint) {
      matrix.print(use12HourFormat ? clock.dateFormat("g", screen_dt) : clock.dateFormat("G", screen_dt));
      if (use12HourFormat ? strlen(clock.dateFormat("g", screen_dt)) != strlen(clock.dateFormat("g", new_dt)) : strlen(clock.dateFormat("G", screen_dt)) != strlen(clock.dateFormat("G", new_dt))) {
        matrix.setCursor(currentMinuteCursorX, TOP_CURSOR_Y);
        matrix.setTextColor(eraseColor);
        matrix.print(clock.dateFormat("i", screen_dt));
        matrix.print(" ");
        matrix.print(clock.dateFormat("A", screen_dt));
        if (strlen(new_hour.c_str()) == 2) currentMinuteCursorX = cursor_x + 3*TEXT_WIDTH + 3*TEXT_H_SPACING;
        else currentMinuteCursorX = cursor_x + 2*TEXT_WIDTH + 2*TEXT_H_SPACING;
      }
      
      setMatrixToTimeCursorPosition();
      matrix.setTextColor(hourColor);
      matrix.print(new_hour);

      setMatrixToTimeCursorPosition();
    }
    
    if (strlen(new_hour.c_str()) == 2) matrix.print("   ");
    else matrix.print("  ");
    
    matrix.setCursor(currentMinuteCursorX, TOP_CURSOR_Y);
    matrix.setTextColor(eraseColor);
    matrix.print(clock.dateFormat("i", screen_dt));
    matrix.setCursor(currentMinuteCursorX, TOP_CURSOR_Y);
    matrix.setTextColor(minuteColor);
    matrix.print(clock.dateFormat("i", new_dt));

    // If the time format is 12 hour, then AM/PM needs to be drawn if this changes, or if the screen is blank, or if the number of digits of the hour changes (prompting a shift of the letters/digits)
    if (use12HourFormat && (clock.dateFormat("A", screen_dt)[0] != clock.dateFormat("A", new_dt)[0] || newMatrixPrint || strlen(clock.dateFormat("g", screen_dt)) != strlen(clock.dateFormat("g", new_dt)))) {
      matrix.print(" ");
      int cursor_x = matrix.getCursorX();
      int cursor_y = matrix.getCursorY();
      matrix.setTextColor(eraseColor);
      matrix.print(clock.dateFormat("A", screen_dt));
      matrix.setCursor(cursor_x, cursor_y);
      matrix.setTextColor(amColor);
      matrix.print(clock.dateFormat("A", new_dt));
    }
  }
}

void printDateLineIfNeeded() {
  matrix.setTextColor(eraseColor);
  setMatrixToDateCursorPosition();

  // Variables that store where the month is printed
  byte cursor_x = matrix.getCursorX();
  
  // Tells where the day needs to go (depends on whether the month has one or two digits)
  int month_offset = strlen(clock.dateFormat("n", screen_dt));
  
  if (newMatrixPrint) { // If the screen is blank, then the proper location of the day needs to be determined
    if (month_offset == 2) currentDayCursorX = cursor_x + 3*TEXT_WIDTH + 3*TEXT_H_SPACING;
    else currentDayCursorX = cursor_x + 2*TEXT_WIDTH + 2*TEXT_H_SPACING;
  }

  // Handle when the date changes - the entire row is cleared if the month changes, but only the day is updated otherwise
  if (new_dt.day != screen_dt.day || newMatrixPrint) {
    String new_month = clock.dateFormat("n", new_dt);
    if (new_dt.month != screen_dt.month || newMatrixPrint || strlen(clock.dateFormat("j", screen_dt)) != strlen(clock.dateFormat("j", new_dt))) {
      matrix.print(clock.dateFormat("n", screen_dt));
      matrix.print("/");
      matrix.setCursor(currentDayCursorX, MIDDLE_CURSOR_Y);
      matrix.setTextColor(eraseColor);
      matrix.print(clock.dateFormat("j", screen_dt));
      matrix.print("/");
      matrix.print(clock.dateFormat("y", screen_dt));
      if (strlen(new_month.c_str()) == 2) currentDayCursorX = cursor_x + 3*TEXT_WIDTH + 3*TEXT_H_SPACING;
      else currentDayCursorX = cursor_x + 2*TEXT_WIDTH + 2*TEXT_H_SPACING;
      setMatrixToDateCursorPosition();
      matrix.setTextColor(monthColor);
      matrix.print(clock.dateFormat("n", new_dt));
      matrix.print("/");
      setMatrixToDateCursorPosition();
    }
    
    if (strlen(new_month.c_str()) == 2) matrix.print("   ");
    else matrix.print("  ");
    
    matrix.setTextColor(eraseColor);
    matrix.print(clock.dateFormat("j", screen_dt));
    
    matrix.setCursor(currentDayCursorX, MIDDLE_CURSOR_Y);
    matrix.setTextColor(dayColor);
    matrix.print(clock.dateFormat("j", new_dt));
    matrix.print("/");

    if (new_dt.month != screen_dt.month || newMatrixPrint || strlen(clock.dateFormat("j", screen_dt)) != strlen(clock.dateFormat("j", new_dt))) {
      matrix.setTextColor(yearColor);
      matrix.print(clock.dateFormat("y", new_dt));
    }
  }
}

void printBottomLineIfNeeded() {
  setMatrixToBottomCursorPosition();

  // Handle when the date changes, so the day of the week will be updated
  if (new_dt.day != screen_dt.day || newMatrixPrint) {
    matrix.setTextColor(eraseColor);
    matrix.print(String(clock.dateFormat("D", screen_dt)).substring(0, 2));
    setMatrixToBottomCursorPosition();
    matrix.setTextColor(dayOfWeekColor);
    matrix.print(String(clock.dateFormat("D", new_dt)).substring(0, 2));
  }

  // Handle when the temperature changes, so the new temp will be printed
  if (newTemp != screenTemp || newMatrixPrint) {
    matrix.setCursor(TEMP_CURSOR_X, BOTTOM_CURSOR_Y);
    matrix.setTextColor(eraseColor);
    matrix.print(screenTemp);

    matrix.setCursor(TEMP_CURSOR_X, BOTTOM_CURSOR_Y);
    matrix.setTextColor(tempColor);
    matrix.print(newTemp);
    if (screenTemp >= 100 || newMatrixPrint) matrix.print(useFahrenheit ? "F" : "C");
    screenTemp = newTemp;
  }

  // Handle when the humidity changes, so the new hum will be printed
  if (newHum != screenHum || newMatrixPrint) {
    matrix.setCursor(HUM_CURSOR_X, BOTTOM_CURSOR_Y);
    matrix.setTextColor(eraseColor);
    matrix.print(screenHum);

    matrix.setCursor(HUM_CURSOR_X, BOTTOM_CURSOR_Y);
    matrix.setTextColor(humColor);
    matrix.print(newHum);
    if (screenHum >= 100 || newMatrixPrint) matrix.print("%");
    screenHum = newHum;
  }

  // If the matrix was blank before, now indicate that the screen is no longer blank
  if (newMatrixPrint) {
    newMatrixPrint = false;
  }
}


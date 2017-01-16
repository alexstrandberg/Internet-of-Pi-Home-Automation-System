# Internet of Pi Home Automation System
The code for my Raspberry Pi-powered home automation system that uses a Raspberry Pi and an Arduino Mega, along with other components to control appliances in a room from an iOS app and act as an alarm clock.

* Four PowerSwitch Tails turn appliances in a room on or off.
* The signals to control the PowerSwitch Tails are sent over 3.5mm audio cables.
* The appliances are turned on or off manually or based on a schedule or external sensors.
* For example, when the room is too warm, a fan can be configured to turn on.
* When a person enters the room, a light can be configured to turn on.
* The RGB LED Matrix shuts off when the room is dark.
* A reed switch and foot switch notify when a door is opened and when a person leaves the room, respectively.
* A Pimoroni Display-O-Tron HAT connected to the Raspberry Pi allows the user to manually control appliances and interact with the system.
* The system acts as an alarm clock by playing music at a scheduled time to wake up the user.

[home_automation_system.ino](home_automation_system.ino) explains the system's wiring.

The system has three main parts:

1. Raspberry Pi 2 Model B - Runs Python script, communicates with Parse Server and Arduino Mega.
2. Arduino Mega - Controls RGB LED Matrix, appliances, and real-time clock.  Reads data from sensor inputs.
3. Parse Server - Database for the system, hosted for free on Heroku.

Check out the video for this project: [https://youtu.be/zhU8cMW9_EU](https://youtu.be/zhU8cMW9_EU)

The code was written by Alex Strandberg and is licensed under the MIT License, check LICENSE for more information.

## Parse, Python, and iOS App Setup:

1. Install all of the external libraries linked at the bottom.
2. Place an mp3 file with the name **alarm.mp3** to be used for the alarm feature.
3. Follow this [tutorial](https://devcenter.heroku.com/articles/deploying-a-parse-server-to-heroku) to set up a Parse Server instance on Heroku for free.  Choose a secure APPLICATION_ID and make a note of this, along with the server URL. 
4. Place the [main.js](main.js) file in the cloud folder of the Parse Server files.
5. Deploy the newly-added code to Heroku (from the dashboard).
6. Set the Server URL and Application ID in [homeautomationsystem.py](home_automation_system/homeautomationsystem.py) and [AppDelegate.swift](iOS App/Internet of Pi/AppDelegate.swift) based on your Parse configuration.  
7. Install [Parse Dashboard](https://github.com/ParsePlatform/parse-dashboard).
8. Create custom Parse classes with columns as described below.


## Running the Home Automation System:
The Python code needs to be in a folder called home_automation system.  To run the system: from the command line, navigate to the directory that this folder is in, and enter the command ```python home_automation_system```.  Alternatively, the provided [rc.local](rc.local) file (place in the /etc/ folder) will run the script at startup.

## Parse Custom Class Setup:
### Action:
* enabled - Boolean
* state - Number
* appliance - Pointer (to Appliance class)
* event - String

### Alarm:
* enabled - Boolean
* repeats - Boolean
* when - Array (Date objects are stored)
* soundAlarm - Boolean

### Appliance:
* enabled - Boolean
* applianceId - Number
* name - String
* state - Number

### Schedule:
* enabled - Boolean
* appliance - Pointer (to Appliance class)
* start - Array (Date objects are stored)
* end - Array (Date objects are stored)
* recurring - Boolean

### SensorData:
* temperature - Number
* humidity - Number
* light - Number
* reedSwitch - String
* footSwitch - String

### Settings:
* useFahrenheit - Boolean
* use12HourFormat - Boolean
* lightThreshold - Number
* temperatureThreshold - Number
* humidityThreshold - Number
* systemFlag - String (Default value: "running")
* actionLastRan - Date (Initial value: Current Date)

## External Libraries:
### Arduino
* [EEPROM](https://www.arduino.cc/en/Reference/EEPROM)
* [Timer3](http://playground.arduino.cc/Code/Timer1)
* [Wire](https://www.arduino.cc/en/Reference/Wire)
* [Adafruit_GFX](https://github.com/adafruit/Adafruit-GFX-Library)
* [RGBmatrixPanel](https://github.com/adafruit/RGB-matrix-Panel)
* [Adafruit_Sensor](https://github.com/adafruit/Adafruit_Sensor)
* [Adafruit_TSL2591](https://github.com/adafruit/Adafruit_TSL2591_Library)
* [Adafruit_SHT31](https://github.com/adafruit/Adafruit_SHT31)
* [Adafruit_MAX31865](https://github.com/adafruit/Adafruit_MAX31865)
* [Arduino-DS3231](https://github.com/jarzebski/Arduino-DS3231)

### Python 
* [ParsePy](https://github.com/milesrichardson/ParsePy)
* [dot3k](https://github.com/pimoroni/dot3k)

### iOS (Cocoapods)
* [Parse](https://cocoapods.org/pods/Parse)
* [SpinKit](https://cocoapods.org/pods/SpinKit)
* [MBProgressHUD](https://cocoapods.org/pods/MBProgressHUD)
* [ATHMultiSelectionSegmentedControl](https://cocoapods.org/pods/ATHMultiSelectionSegmentedControl)


Icons used in iOS App: Made by [Webalys Freebies](http://www.flaticon.com/authors/webalys-freebies "Webalys Freebies"), [Freepik](http://www.freepik.com "Freepik"), [Vaadin](http://www.flaticon.com/authors/vaadin "Vaadin"), and [Egor Rumyantsev](http://www.flaticon.com/authors/egor-rumyantsev "Egor Rumyantsev") from [www.flaticon.com](http://www.flaticon.com "Flaticon") are licensed by [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/ "Creative Commons BY 3.0")

*   [Smart Home Icon](http://www.flaticon.com/free-icon/smart-home_116048)
*   [Settings Icon](http://www.flaticon.com/free-icon/settings-work-tool_70367)
*   [Plug Icon](http://www.flaticon.com/free-icon/plug_107092)
*   [Clock Icon](http://www.flaticon.com/free-icon/clock_114264)
*   [Bell Icon](http://www.flaticon.com/free-icon/bell_162722)
*   [Gauge Icon](http://www.flaticon.com/free-icon/gauge_86913)


# controls.py
# Alex Strandberg (https://github.com/alexstrandberg)
# December 28, 2016
""" controls module for Internet of Pi

    This module provides the class Controls, which interfaces with the Pimoroni's Display-o-Tron HAT
    It handles button presses, outputting information to the LCD display, and setting the backlight.

    In addition, this class also handles audio playback for the alarm feature.

"""

import dothat.backlight as backlight
import dothat.lcd as lcd
import dothat.touch as touch
import subprocess, time

ALARM_FILE = '/home/pi/home_automation_system/alarm.mp3' # Alarm mp3 file

class Controls:
    """ Instance is the main form of input and output for the system

    Interfaces with Pimoroni's Display-o-Tron HAT and plays an mp3 file for the alarm feature.

    Instance Attributes:

        _appliances          [Queryset of all the appliances in the system - Parse custom class: Appliance]
        _currentApplianceID  [Int, ID number of the appliance displayed on the LCD]
        _alarmProcess        [Popen object of the process that plays the alarm mp3 file, or None if no alarm is playing]
        _alarmFinished       [Boolean, True if alarm has been dismissed, False otherwise ]
        _forceDisplayOn      [Boolean, True if button pressed (desire for time display to be on regardless of light level), False otherwise]
        _ignoreNextAlarm     [Boolean, True if button pressed (desire for next alarm to be silenced), False otherwise]

    _alarmFinished, _forceDisplayOn, _displayIsForcedOn have getter methods used by HomeAutomationSystem
    """
    def __init__(self, appliances):
        """ Initializes a new Controls object

        Parameter: appliances [Queryset to which self._appliances is set]
        """
        lcd.set_cursor_position(0, 0)
        backlight.rgb(0, 255, 0)
        self._appliances = appliances
        self._currentApplianceID = 0
        self._alarmProcess = None
        self._alarmFinished = False
        self._forceDisplayOn = False
        self._forceDisplayOnTime = time.time()
        self._displayIsForcedOn = False
        self._ignoreNextAlarm = False

    def update(self, appliances, sensorData, config):
        """ Method that displays information on the LCD - one appliance and it's state, and whether alarm is silenced

        Parameter: appliances [Queryset to which self._appliances is set]
        Parameter: sensorData [SensorData object with latest info]
        Parameter: config     [Settings object with latest configuration info]
        """
        self._appliances = appliances
        lcd.set_cursor_position(0, 0)
        name = self._appliances[self._currentApplianceID].name[0:16]
        state = '[ON] ' if self._appliances[self._currentApplianceID].state == 1 else '[OFF]'
        lcd.write(name + ' '*(16-len(name)))
        lcd.set_cursor_position(0, 1)
        lcd.write(state)
        if self._ignoreNextAlarm:
            lcd.set_cursor_position(0, 2)
            lcd.write('ALARM SILENCED')
        # If alarm is not going off and light sensor value is below threshold, shut backlight off
        if config is not None and sensorData is not None and sensorData.light < config.lightThreshold and not self._displayIsForcedOn and self._alarmProcess is None:
            backlight.rgb(0, 0, 0)
        elif self._alarmProcess is None: # Otherwise, set backlight to green (if alarm isn't going off)
            backlight.rgb(0, 255, 0)

    def handleButton(self, channel):
        """ Method that handles button presses.
        Backlight changes to red after button press while loading.

        Parameter: channel [Int, what button was pressed - constants from dothat/touch.py]
        """
        backlight.rgb(255, 0, 0)
        if channel == touch.BUTTON: # Select button pressed: turn current appliance on or off
            currentAppliance = self._appliances[self._currentApplianceID]
            if currentAppliance.state == 0 and currentAppliance.enabled:
                currentAppliance.state = 1
                currentAppliance.save()
            else:
                currentAppliance.state = 0
                currentAppliance.save()
        elif channel == touch.LEFT and self._currentApplianceID > 0: # Left button pressed: go to previous appliance
            self._currentApplianceID -= 1
        elif channel == touch.RIGHT and self._currentApplianceID < len(self._appliances)-1: # Right button pressed: go to next appliance
            self._currentApplianceID += 1
        elif channel == touch.DOWN: # Down button pressed: turn off alarm or silence the next alarm
            if self._alarmProcess is not None:
                self._alarmProcess.terminate()
                self._alarmProcess = None
                self._alarmFinished = True
                lcd.set_cursor_position(0, 2)
                lcd.write('     ')
                backlight.rgb(0, 255, 0)
            elif not self._ignoreNextAlarm:
                self._ignoreNextAlarm = True
            else:
                self._ignoreNextAlarm = False
                lcd.set_cursor_position(0, 2)
                lcd.write('              ')
        elif channel == touch.CANCEL: # Cancel button pressed: force display on for 10 seconds
            if not self._displayIsForcedOn:
                self._forceDisplayOn = True
                self._displayIsForcedOn = True
                self._forceDisplayOnTime = time.time()
                backlight.rgb(0, 255, 0)

    def playAlarm(self):
        """ Method that starts a process to play an mp3 file for the alarm.
        Adds an alarm message to the LCD, and sets the backlight blue.
        """
        if self._alarmProcess is None and not self._ignoreNextAlarm:
            self._alarmProcess = subprocess.Popen(['mpg123', ALARM_FILE, '--loop', '-1'])
            lcd.set_cursor_position(0, 2)
            lcd.write('ALARM')
            backlight.rgb(0, 0, 255)
        else:
            self._alarmFinished = True
            self._ignoreNextAlarm = False
            lcd.set_cursor_position(0,2)
            lcd.write('              ')

    def checkAlarmFinished(self):
        """ Method that allows HomeAutomationSystem to see if the alarm finished.
        """
        if self._alarmFinished:
            self._alarmFinished = False
            self._ignoreNextAlarm = False
            return True
        return False

    def checkForceDisplayOn(self):
        """ Method that allows HomeAutomationSystem to see if it should force the display on.
        """
        if self._forceDisplayOn:
            self._forceDisplayOn = False
            return True
        return False

    def checkForceDisplayOff(self):
        """ Method that allows HomeAutomationSystem to see if it should force the display back to its normal setting.
        """
        if self._displayIsForcedOn and time.time() - self._forceDisplayOnTime >= 10:
            self._displayIsForcedOn = False
            return True
        return False
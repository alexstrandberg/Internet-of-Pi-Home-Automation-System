# homeautomationsystem.py
# Alex Strandberg (https://github.com/alexstrandberg)
# December 28, 2016
""" homeautomationsystem module for Internet of Pi

    This file contains the main controller for the system, including code to connect to the Parse Open Source backend

"""

import time, os, datetime

os.environ["PARSE_API_ROOT"] = ''

from serialcomm import *
from controls import *
from parseclasses import *

from parse_rest.connection import register
from parse_rest.datatypes import Function
from parse_rest.connection import ParseBatcher

APPLICATION_ID = ''

register(APPLICATION_ID, '')

# Cloud Code Functions
processScheduling = Function('processScheduling')
processAlarms = Function('processAlarms')

NUM_APPLIANCES = 4

class HomeAutomationSystem:
    """ Instance is the primary controller for Internet of Pi

    Instance Attributes:

        _batcher    [ParseBatcher instance: allows saving of multiple objects at once.]
        _handlingButton [Boolean: True if a button press is being handled (to prevent main loop from executing again until done), False otherwise.]
        _appliances     [Queryset of Appliance objects, ordered by applianceId.]
        _config         [Settings object: Settings store in Parse.]
        _serialComm     [SerialComm instance: for communication with Arduino.]
        _loopCounter    [Int: 0 if new sensor data should be requested from Arduino, 3 if cloud functions should run. Increments every iteration of loop (0-3).]
        _lastTime       [time object: Used to check if daylight savings time change has occurred.]
        _running        [Boolean: Flag used to determine if system should keep running (True), False otherwise.]
    """

    def __init__(self):
        """ Initializes a new HomeAutomationSystem instance.

        Sets initial states for instance attributes.

        """
        self._batcher = ParseBatcher()
        self._handlingButton = False
        self._appliances = Appliance.Query.all().order_by('applianceId')
        config = Settings.Query.all()
        if len(config) == 0: # When the system is run for the first time, initialize the configuration
            self._config = Settings(useFahrenheit=True, use12HourFormat=True, lightThreshold=5, temperatureThreshold=22.2, humidityThreshold=33, systemFlag="running", actionLastRan=datetime.datetime.now())
            self._config.save()
        else:
            self._config = config[0]
        self._serialComm = None
        self._loopCounter = 0
        self._lastTime = time.localtime()
        self._running = True
        if len(self._appliances) == 0: # When the system is run for the first time, initialize the appliances
            appliances = []
            for x in range(NUM_APPLIANCES):
                appliances.append(Appliance(applianceId=x, name='Appliance '+str(x), enabled=1, state=0))
            self._batcher.batch_save(appliances)
            self._appliances = Appliance.Query.all().order_by('applianceId')


    def run(self):
        """ Method that starts the system.

        Establishes serial connection instance, runs main loop, and handles errors by logging to error file.
        """
        while self._serialComm == None:
            try:  # Try establishing serial connection
                self._serialComm = SerialComm()
                time.sleep(5)
            except Exception as err:
                time.sleep(10)  # Wait ten seconds before trying to connect to Arduino again
        self._controls = Controls(self._appliances)

        while self._running:
            try:
                if not self._handlingButton:
                    self.mainLoop()
            except KeyboardInterrupt:
                self._running = False
            except Exception as err:
                with open("/home/pi/home_automation_system/errorlog.txt", "a") as myfile:
                    myfile.write(datetime.datetime.today().strftime('%c'))
                    myfile.write('\n')
                    myfile.write(str(err))
                    myfile.write('\n')
                    myfile.close()
                time.sleep(5)

        # Script will stop
        self._serialComm.close()

    def handleButton(self, channel):
        """ Method that tells the Controls instance of a button press.

        Parameter: channel [Int, what button was pressed - constants from dothat/touch.py]
        """
        if not self._handlingButton:
            self._handlingButton = True
            if self._controls is not None:
                self._controls.handleButton(channel)
            self._handlingButton = False

    def mainLoop(self):
        """ Main segment of code that runs repeatedly.

        Runs cloud code to determine if schedules are starting or ending (and update appliance states accordingly).
        Requests and reads serial data (SerialComm instance).
        Checks if alarms should go off (Controls instance) or system settings have changed.
        Can sync Arduino and Raspberry Pi's clocks, or shutdown/reboot pi if instructed to from Parse.
        """
        self._serialComm.readFromSerial()
        if self._loopCounter == 0: # Request data every 4 iterations of the loop
            self._serialComm.requestSensorData()
            self._loopCounter += 1
        elif self._loopCounter != 3:
            self._loopCounter += 1
        else: # self._loopCounter == 3
            self._loopCounter = 0
            processScheduling()
            self._appliances = Appliance.Query.all().order_by('applianceId')
            self._serialComm.updateAppliances(self._appliances)
            processAlarms()
            alarms = Alarm.Query.filter(soundAlarm=True)
            for alarm in alarms:
                alarm.soundAlarm = False
                alarm.save()
                if not alarm.repeats:
                    alarm.delete()
                self._controls.playAlarm()
                self._serialComm.setDisplayMode(DISPLAY_IGNORE)
            self._config = Settings.Query.all()[0]
            newTime = time.localtime()
            # Detect daylight savings change and update Arduino clock if needed
            if self._lastTime.tm_isdst != newTime.tm_isdst or self._config.systemFlag == 'updateDateTime':
                self._serialComm.syncTime()
                if self._config.systemFlag == 'updateDateTime':
                    self._config.systemFlag = 'running'
                    self._config.save()
            self._lastTime = newTime
            self._serialComm.syncSettings(self._config)
            if self._config.systemFlag == 'shutdownPi':
                self._config.systemFlag = 'running' # When the script runs again, the script knows to run
                self._config.save()
                self._running = False
                os.system('/sbin/shutdown -h now')
            elif self._config.systemFlag == 'rebootPi':
                self._config.systemFlag = 'running'  # When the script runs again, the script knows to run
                self._config.save()
                self._running = False
                os.system('/sbin/shutdown -r now')
            self._controls.update(self._appliances, self._serialComm.getLastSensorData(), self._config)
        if self._controls.checkAlarmFinished():
            self._serialComm.setDisplayMode(DISPLAY_CLEAR_WHEN_DARK)
        if self._controls.checkForceDisplayOn():
            self._serialComm.setDisplayMode(DISPLAY_IGNORE)
        elif self._controls.checkForceDisplayOff():
            self._serialComm.setDisplayMode(DISPLAY_CLEAR_WHEN_DARK)
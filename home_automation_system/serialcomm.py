# serialcomm.py
# Alex Strandberg (https://github.com/alexstrandberg)
# December 28, 2016
""" serialcomm module for Internet of Pi

    This module provides the class SerialComm, which interfaces with the Arduino Mega.
    The Arduino Mega controls the appliances and RGB Matrix, and reads data from sensors.

"""
import subprocess, serial, datetime
from parseclasses import *

DISPLAY_IGNORE = 'IGNORE'
DISPLAY_CLEAR_WHEN_DARK = 'CLEAR_WHEN_DARK'
DISPLAY_DISABLE_WHEN_DARK = 'DISABLE_WHEN_DARK'

class SerialComm:
    """ Instance is Raspberry Pi's way of communicating with the Arduino Mega.

    Instance Attributes:

        _applianceStates     [List of Ints: representing whether each appliance is on (1) or off (0)]
        _currentSettings     [Parse Class - Settings object: The most recently fetched settings for the system]
        _latestSensorData    [Parse Class - SensorData: The most recent sensor data]
        _reedSwitch          [String: The value of the reed switch]
        _footSwitch          [String: The value of the foot switch]
    """
    def __init__(self):
        """ Initializes a new SerialComm instance.

        Establishes Serial connection to Arduino Mega and sets instance attributes to initial values.

        """
        self._applianceStates = []
        self._currentSettings = None
        self._latestSensorData = None
        self._reedSwitch = 'CLOSED'
        self._footSwitch = 'RELEASED'
        # Finding the serial port
        port = subprocess.check_output("dmesg | grep 'cdc_acm 1.1' | tail -1", shell=True).split(':')
        if port == ['']:
            raise Exception('Could not find serial port')
        port = '/dev/' + port[2].strip()

        try:
            self._ser = serial.Serial(
                port=port,
                baudrate=9600,
                timeout=1
            )
        except NameError:
            raise Exception('Could not connect to Arduino')


    def _sendSerialMessage(self, command, data):
        """ Method that sends serial messages according to the protocol found in home_automation_system.ino
        """
        sentence = command + '!' + str(len(data)) + '@' + ','.join(data)
        CRC = 0

        for s in sentence:
            CRC ^= ord(s)

        self._ser.write('$')
        self._ser.write(sentence)
        self._ser.write('*')
        self._ser.write(hex(CRC))
        self._ser.write('\n')


    def _handleSerialMessage(self, sentence):
        """ Method that decodes the provided serial message.

        Parameter: sentence [String: Original serial message]

        Returns: command (String) and related data
        """
        if sentence.find('$') != -1 and sentence.find('*') != -1:
            received_checksum = int(sentence[sentence.find('*') + 1:], 16)
            sentence = sentence[sentence.find('$') + 1:sentence.find('*')]
            CRC = 0
            for s in sentence:
                CRC ^= ord(s)

            if received_checksum != CRC:
                raise Exception('Checksum mismatch')

            return sentence[:sentence.find('!')], sentence[sentence.find('@') + 1:].split(',')


    def updateAppliances(self, appliances):
        """ Method that compares the current appliance states with those states store on Parse.
        Sends a serial message with new appliance states if the above two are different.

        Parameter: appliances [Queryset of type Appliance]
        """
        states = []
        for appliance in appliances:
            states.append(str(appliance.state))
        if states != self._applianceStates or len(self._applianceStates) == 0:
            self._sendSerialMessage('APP', states)
            self._applianceStates = states


    def syncSettings(self, settings):
        """ Method that compares the current system settings with the newly provided system settings.
        Sends a serial message with new settings if the above two are different.

        Parameter: settings [Parse Class - Settings: the newest settings]
        """
        if self._currentSettings is not None:
            if self._currentSettings.useFahrenheit != settings.useFahrenheit or self._currentSettings.use12HourFormat != settings.use12HourFormat:
                formattingData = ['1' if settings.use12HourFormat else '0', '1' if settings.useFahrenheit else '0']
                self._sendSerialMessage('SET_FORMATTING', formattingData)
            if self._currentSettings.lightThreshold != settings.lightThreshold:
                self._sendSerialMessage('SET_LIGHT_THRESHOLD', [str(settings.lightThreshold)])
        self._currentSettings = settings


    def setDisplayMode(self, mode):
        """ Method that sends a serial message to change the display mode.

        Parameter: mode [String: Display Mode Constant (see top of file)]
        """
        if mode == DISPLAY_IGNORE or mode == DISPLAY_CLEAR_WHEN_DARK or mode == DISPLAY_DISABLE_WHEN_DARK:
            self._sendSerialMessage('ENABLE_MATRIX', [mode])


    def close(self):
        """ Method that closes the serial connection.
        """
        self._ser.close()


    def readFromSerial(self):
        """ Method that handles serial messages coming from the Arduino.
        Processes latest sensor data and uploads to Parse
        """
        reading = self._ser.readline().decode()
        if reading != '':
            command, data = self._handleSerialMessage(reading)
            if command == 'SENSOR':
                temperature = float(data[0])
                humidity = float(data[1])
                light = int(data[2])
                reedSwitch = data[3]
                footSwitch = data[4]
                self._latestSensorData = SensorData(temperature = temperature, humidity = humidity, light = light, reedSwitch = reedSwitch, footSwitch = footSwitch)
                self._latestSensorData.save()


    def requestSensorData(self):
        """ Method that asks Arduino for latest sensor data.
        """
        self._sendSerialMessage('GET_SENSOR', [])


    def getLastSensorData(self):
        """ Method that returns the latest sensor data from the Arduino.
        """
        return self._latestSensorData


    def syncTime(self):
        """ Method that updates the time on the Arduino's real time clock with the system time.
        Can be triggered from app manually, or automatically when daylight savings time goes into effect or ends.
        """
        now = datetime.datetime.now() + datetime.timedelta(milliseconds=1500)
        self._sendSerialMessage('SET_DATE_TIME', [str(now.year), str(now.month), str(now.day), str(now.hour), str(now.minute), str(now.second)])


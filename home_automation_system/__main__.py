# !/usr/bin/python

# __main__.py
# Alex Strandberg (https://github.com/alexstrandberg)
# December 28, 2016
""" __main__ module for Internet of Pi

This is the module with the application code.  Make sure that this module is
in a folder with the following files:

 - homeautomationsystem.py (Handles the system's operation - interfacing with each component)
 - serialcomm.py (Handles serial communication with the Arduino Mega)
 - controls.py (Manages button input and LCD output - Display-o-Tron HAT)
 - parseclasses.py (Provides skeleton code for custom Parse classes)
 - alarm.mp3 (NOTE: You need to provide this file, can be any mp3 song

The following Python libraries must be installed for the code to run:
 - ParsePy (https://github.com/milesrichardson/ParsePy)
 - Display-o-Tron HAT (https://github.com/pimoroni/dot3k)

See README.md for information on how to set up an open source Parse Server instance on Heroku
(with the necessary Parse Custom Class and Parse Cloud Code setup).

"""

from homeautomationsystem import *
import dothat.touch as touch # For button presses

# Application code
if __name__ == '__main__':
    system = HomeAutomationSystem()

    # Button presses are handled by controls.py, but need to go through the HomeAutomationSystem class,
    # so the system waits to run its main loop again once the button presses are processed.
    # Also, the @touch.on decorator does not allow for a class method to be used, so this handleButton method
    # calls the handleButton method in HomeAutomationSystem.
    @touch.on([touch.BUTTON, touch.LEFT, touch.RIGHT, touch.DOWN, touch.CANCEL])
    def handleButton(channel, event):
        """ Method that tells the HomeAutomationSystem instance of a button press.

        Parameter: channel [Int, what button was pressed - constants from dothat/touch.py]
        """
        system.handleButton(channel)

    # System starts running, and this method runs until the system is shut down
    system.run()
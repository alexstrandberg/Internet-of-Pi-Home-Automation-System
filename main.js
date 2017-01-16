Parse.Cloud.define("processScheduling", function(req, res) {
    // Function that iterates through enabled schedules and checks if a schedule is starting or ending.
    // To determine this, each schedule stores arrays for the starting and end times (each day of the week in the schedule has an array entry).
    // Whenever a schedule's date and time for starting or ending is met (when the current date/time is greater than the stored one),
    // the appliance state is changed accordingly, and one week is added to the corresponding array entry (ex: if it's Monday, then next Monday)

    var now = new Date();

    var startQuery = new Parse.Query("Schedule");
    startQuery.lessThan("start", now);
    startQuery.equalTo("enabled", true);
    startQuery.include("appliance");
    startQuery.find().then(function (schedules) {
        schedules.forEach(function(schedule) {
            var startArray = schedule.get("start");
            for (var i = 0; i < startArray.length; i++) {
                if (startArray[i] < now) {
                    startArray[i].setDate(startArray[i].getDate() + 7);
                }
            }
            schedule.set("start", startArray); // Add a week to the start date
            schedule.get("appliance").set("state", 1);
            schedule.save();
        });

        res.success({});

        var endQuery = new Parse.Query("Schedule");
        endQuery.lessThan("end", now);
        endQuery.include("appliance");
        endQuery.equalTo("enabled", true);

        endQuery.find().then(function (schedules) {
            schedules.forEach(function(schedule) {
                var endArray = schedule.get("end");
                for (var i = 0; i < endArray.length; i++) {
                    if (endArray[i] < now) {
                        endArray[i].setDate(endArray[i].getDate() + 7);
                    }
                }
                schedule.set("end", endArray); // Add a week to the end date
                schedule.get("appliance").set("state", 0);
                schedule.save();
                if (schedule.get("recurring") == false) {
                    schedule.destroy({
                        success: function() {
                        },
                        error: function() {
                        }
                    })
                }
            });
            res.success({});
        }, function (err) {
            res.error(err);
        });
    }, function (err) {
        res.error(err);
    });
});

Parse.Cloud.define("processAlarms", function(req, res) {
    // Function that iterates through enabled alarms and checks if it is time for an alarm to go off.
    // To determine this, each alarm stores arrays for the alarm times (each day of the week in the alarm has an array entry).
    // Whenever an alarm's date and time for starting or ending is met (when the current date/time is greater than the stored one),
    // the alarm is set to go off, and one week is added to the corresponding array entry (ex: if it's Monday, then next Monday)

    var now = new Date();

    var query = new Parse.Query("Alarm");
    query.lessThan("when", now);
    query.equalTo("enabled", true);

    query.find().then(function (alarms) {
        alarms.forEach(function(alarm) {
            var whenArray = alarm.get("when");
            for (var i = 0; i < whenArray.length; i++) {
                if (whenArray[i] < now) {
                    whenArray[i].setDate(whenArray[i].getDate() + 7);
                }
            }
            alarm.set("when", whenArray); // Add a week to the alarm date
            alarm.set("soundAlarm", true);
            alarm.save();
        });

        res.success({});
    }, function (err) {
        res.error(err);
    });
});

Parse.Cloud.beforeSave("Appliance", function(req, res) {
    // Function that cancels any one-time schedules and disables any recurring schedules/actions for an appliance that is being set to disabled.
    if (!req.object.get("state")) { // If turning appliance off, cancel any one-time schedules
        var oneTimeQuery = new Parse.Query("Schedule");
        oneTimeQuery.equalTo("recurring", false);
        oneTimeQuery.equalTo("appliance", req.object);
        oneTimeQuery.find().then(function(schedules) {
            schedules.forEach(function(schedule) {
                schedule.destroy({
                    success: function() {
                    },
                    error: function() {
                    }
                })
            }, function (err) {
               res.error(err);
            });
        })
    }
    if (!req.object.get("enabled")) { // If disabling appliance, disable any recurring schedules/actions for that appliance
        var schedulesQuery = new Parse.Query("Schedule");
        schedulesQuery.equalTo("appliance", req.object);
        schedulesQuery.find().then(function(schedules) {
            schedules.forEach(function(schedule) {
                schedule.set("enabled", false);
                schedule.save();
            }, function (err) {
                res.error(err);
            });
        }, function (err) {
            res.error(err);
        });

        var actionsQuery = new Parse.Query("Action");
        actionsQuery.equalTo("appliance", req.object);
        actionsQuery.find().then(function(actions) {
            actions.forEach(function(action) {
                action.set("enabled", false);
                action.save();
            }, function (err) {
                res.error(err);
            });
        }, function (err) {
            res.error(err);
        });
    }
    res.success();
});

Parse.Cloud.beforeSave("Schedule", function(req, res) {
    // Function that allows for enabling a schedule for a disabled appliance - the appliance must be enabled.
    var appliance = req.object.get("appliance");
    if (req.object.get("enabled") && !appliance.get("enabled")) { // If enabling schedule for disabled appliance, enable the appliance
        appliance.set("enabled", true);
        appliance.save();
    }
    res.success();
});

Parse.Cloud.beforeSave("Action", function(req, res) {
    // Function that allows for enabling an action for a disabled appliance - the appliance must be enabled.
    var appliance = req.object.get("appliance");
    if (req.object.get("enabled") && !appliance.get("enabled")) { // If enabling action for disabled appliance, enable the appliance
        appliance.set("enabled", true);
        appliance.save();
    }
    res.success();
});

Parse.Cloud.beforeSave("SensorData", function(req, res) {
    // Function that checks if any action's criteria are met, and update appliance states accordingly.
    var now = new Date();
    var settingsQuery = new Parse.Query("Settings");
    settingsQuery.find().then(function (settings) {
        var actionLastRan = settings[0].get("actionLastRan");
        if (now - actionLastRan > 30000) { // If at least 30 seconds have passed since the last action event, can check for events
            var lightThreshold = settings[0].get("lightThreshold");
            var temperatureThreshold = settings[0].get("temperatureThreshold");
            var humidityThreshold = settings[0].get("humidityThreshold");
            var actionsQuery = new Parse.Query("Action");
            actionsQuery.equalTo("enabled", true);
            actionsQuery.include("appliance");
            actionsQuery.find().then(function(actions) {
                actions.forEach(function(action) {
                    var matchesCriteria = false;
                    switch (action.get("event")) {
                        case "Door Is Opened":
                            if (req.object.get("reedSwitch") == "OPENED") matchesCriteria = true;
                            break;
                        case "Door Is Closed":
                            if (req.object.get("reedSwitch") == "CLOSED") matchesCriteria = true;
                            break;
                        case "Foot Switch Is Pressed":
                            if (req.object.get("footSwitch") == "PRESSED") matchesCriteria = true;
                            break;
                        case "Light Exceeds Threshold":
                            if (req.object.get("light") >= lightThreshold) matchesCriteria = true;
                            break;
                        case "Light Falls Below Threshold":
                            if (req.object.get("light") <= lightThreshold) matchesCriteria = true;
                            break;
                        case "Temperature Exceeds Threshold":
                            if (req.object.get("temperature") >= temperatureThreshold) matchesCriteria = true;
                            break;
                        case "Temperature Falls Below Threshold":
                            if (req.object.get("temperature") <= temperatureThreshold) matchesCriteria = true;
                            break;
                        case "Humidity Exceeds Threshold":
                            if (req.object.get("humidity") >= humidityThreshold) matchesCriteria = true;
                            break;
                        case "Humidity Falls Below Threshold":
                            if (req.object.get("humidity") <= humidityThreshold) matchesCriteria = true;
                            break;
                    }
                    if (matchesCriteria) { // Matching event has happened, check if appliance's state needs to be updated
                        var appliance = action.get("appliance");
                        if (appliance.get("state") != action.get("state")) {
                            appliance.set("state", action.get("state"));
                            action.save();
                            settings[0].set("actionLastRan", now);
                            settings[0].save();
                        }
                    }
                }, function (err) {
                    res.error(err);
                });
            }, function (err) {
                res.error(err);
            });
        }
    }, function (err) {
        res.error(err);
    });
    res.success();
});
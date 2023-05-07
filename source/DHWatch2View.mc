import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.SensorHistory;
import Toybox.BluetoothLowEnergy;
using Toybox.Activity;
using Toybox.Time.Gregorian as Date;
using Toybox.Time as Time;
using Toybox.ActivityMonitor as Mon;
using Toybox.Math as Math;
import Toybox.Weather;

class DHWatch2View extends WatchUi.WatchFace {

    var bkgImg;
    var batImg;
    var calImg;
    var hrImg;
    var msgImg;
    var stepsImg;
    var BBImg;
    var noBTImg;
    var screenWidth;
    var screenHeight;
    var clockFont;
    var dateFont;
    var statsFont;
    var isLowPowerMode = false;
    var isHidden = false;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        bkgImg = WatchUi.loadResource(Rez.Drawables.GCbkg);
        batImg = WatchUi.loadResource(Rez.Drawables.bat20);
        calImg = WatchUi.loadResource(Rez.Drawables.cal20);
        hrImg = WatchUi.loadResource(Rez.Drawables.hr20);
        msgImg = WatchUi.loadResource(Rez.Drawables.msg20);
        stepsImg = WatchUi.loadResource(Rez.Drawables.steps20);
        BBImg = WatchUi.loadResource(Rez.Drawables.BB20);
        noBTImg = WatchUi.loadResource(Rez.Drawables.BT20);
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        clockFont = WatchUi.loadResource(Rez.Fonts.FontClock);
        dateFont = WatchUi.loadResource(Rez.Fonts.FontDate);
        statsFont = WatchUi.loadResource(Rez.Fonts.FontStats);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Draw components
        drawFigure(dc);
        drawTime(dc);
        drawDate(dc);
        if (!isLowPowerMode && !isHidden) {
            drawBattery(dc);
            drawSteps(dc);
            drawHR(dc);
            drawNoti(dc);
            drawCal(dc);
            drawSeconds(dc);
            drawBB(dc);
            noBT(dc);
        }
    }

    // Show background image
    function drawFigure(dc) {
        dc.drawBitmap(0, 0, bkgImg);
    }

    // Draw time
    function drawTime(dc) {
        // Get system time
        var clockTime = System.getClockTime();
        var hours = clockTime.hour.format("%02d"); // 2-digit hours (24h)
        var minutes = clockTime.min.format("%02d");
        // Display time
        var x = screenWidth / 2;
        var y = screenHeight / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 20, y - 130, clockFont, hours, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 20, y - 30, clockFont, minutes, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawDate(dc) {
        var time = Time.now();
        var date = Date.info(time, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$", [date.day, date.month]);
        var x = screenWidth / 2;
        var y = screenHeight / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 40, y + 95, dateFont, dateString, Graphics.TEXT_JUSTIFY_LEFT); 
    }

    function drawBattery(dc) {
        var sysbat = System.getSystemStats().battery;
        var posX = 208-(208-57)*Math.sin(Math.PI*0.4/4.toFloat());
        var posY = 208-(208-57)*Math.cos(Math.PI*0.4/4.toFloat());
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90-(sysbat*3.6));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var sysbatstr = sysbat.format("%d");
        var batSize = dc.getTextDimensions(sysbatstr, statsFont);
        dc.drawText(posX - Math.round(batSize[0]/2), posY - Math.round(batSize[1]/2) + 12, statsFont, sysbatstr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(posX-15, posY-31, batImg);
    }

    function drawSteps(dc) {
        var posX = 208-(208-57)*Math.sin(Math.PI*(1.2/4.toFloat()));
        var posY = 208-(208-57)*Math.cos(Math.PI*(1.2/4.toFloat()));
        // Get step count; convert into <val>k if > 1000
        var stepCount = Mon.getInfo().steps;
        var stepString;
        if (stepCount < 1000) {
            stepString = stepCount.toString();
        } else {
            var stepkCount = Math.floor(stepCount / 1000);
            stepString = stepkCount.toString() + "k";
        }
        // Get step goal
        var stepGoal = Mon.getInfo().stepGoal;
        // Create widget
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        var stepRatio = stepCount.toFloat() / stepGoal.toFloat();
        if (stepRatio > 0) {
            if (stepRatio < 1) {
                dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90-(360*(stepRatio)));
            } else {
                dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var stepSize = dc.getTextDimensions(stepString, statsFont);
        dc.drawText(posX - Math.round(stepSize[0]/2), posY - Math.round(stepSize[1]/2) + 12, statsFont, stepString, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(posX-15, posY-31, stepsImg);
    }

    function drawHR(dc) {
        var posX = 208-(208-57)*Math.sin(Math.PI*(2.toFloat()/4.toFloat()));
        var posY = 208-(208-57)*Math.cos(Math.PI*(2.toFloat()/4.toFloat()));
        var HRinfo = Activity.getActivityInfo();
        var HRstr = "--";
        if (HRinfo != null) {
            if (HRinfo.currentHeartRate != null) {
                HRstr = HRinfo.currentHeartRate.toString();
            }
        } else {
            var latestHRsample = Mon.getHeartRateHistory(1, true).next();
            if (latestHRsample != null) {
                HRstr = latestHRsample.heartRate.toString();
            } 
        }
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
        var HRSize = dc.getTextDimensions(HRstr, statsFont);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(posX - Math.round(HRSize[0]/2), posY - Math.round(HRSize[1]/2) + 12, statsFont, HRstr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(posX-15, posY-31, hrImg);
    }

    function drawNoti(dc) {
        var posX = 280;
        var posY = 75;
        var notCount = System.getDeviceSettings().notificationCount;
        if (notCount > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(posX, posY, statsFont, notCount.toString(), Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawBitmap(posX-30, posY+8, msgImg);
        }       
    }

    function drawBB(dc) {
        var posX = 208-(208-57)*Math.sin(Math.PI*(2.8/4.toFloat()));
        var posY = 208-(208-57)*Math.cos(Math.PI*(2.8/4.toFloat()));
        // Get BB val; snippet from Garmin
        var BBval = 0;
        var BBString = "--";
        var BBhist = Toybox.SensorHistory.getBodyBatteryHistory({});
        if (BBhist != null) {
            BBval = BBhist.next().data;
            BBString = Math.round(BBval).format("%d");
        }
        // Create widget
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        var BBRatio = BBval.toFloat() / 100.toFloat();
        if (BBRatio > 0) {
            if (BBRatio < 1) {
                dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90-(360*(BBRatio)));
            } else {
                dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var BBSize = dc.getTextDimensions(BBString, statsFont);
        dc.drawText(posX - Math.round(BBSize[0]/2), posY - Math.round(BBSize[1]/2) + 12, statsFont, BBString, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(posX-15, posY-31, BBImg);
    }

    function drawCal(dc) {
        var posX = 208-(208-57)*Math.sin(Math.PI*(3.6/4.toFloat()));
        var posY = 208-(208-57)*Math.cos(Math.PI*(3.6/4.toFloat()));
        // Get cal count; convert into <val>.<val>k if > 1000
        var calCount = Mon.getInfo().calories;
        var calString;
        if (calCount < 1000) {
            calString = calCount.toString();
        } else {
            var calkCount = Math.floor(calCount / 100).toFloat() / 10;
            calString = calkCount.format("%0.1f") + "k";
        }
        // Manually set cal goal to 3k
        var calGoal = 3000;
        // Create widget
        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        var calRatio = calCount.toFloat() / calGoal.toFloat();
        if (calRatio > 0) {
            if (calRatio < 1) {
                dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90-(360*(calRatio)));
            } else {
                dc.drawArc(posX, posY, 40, Graphics.ARC_CLOCKWISE, 90, 90);
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var calSize = dc.getTextDimensions(calString, statsFont);
        dc.drawText(posX - Math.round(calSize[0]/2), posY - Math.round(calSize[1]/2) + 12, statsFont, calString, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(posX-15, posY-31, calImg);
    }

    function drawSeconds(dc) {
        var clockTime = System.getClockTime();
        var minutes = clockTime.min;
        var seconds = clockTime.sec;
        dc.setPenWidth(8);
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
        if (minutes % 2 == 0) {
            // Even minutes, add line
            if (seconds > 0) {
                dc.drawArc(208, 208, 206, Graphics.ARC_CLOCKWISE, 90, 90-(seconds*6));
            }
        } else {
            // Odd minutes, remove line
            if (seconds > 0) {
                dc.drawArc(208, 208, 206, Graphics.ARC_CLOCKWISE, 90-(seconds*6), 90);
            } else {
                dc.drawArc(208, 208, 206, Graphics.ARC_CLOCKWISE, 90, 90);
            }
        }
    }

    function noBT(dc) {
        var BTstate = System.getDeviceSettings().phoneConnected;
        if (BTstate == false) {
            dc.drawBitmap(310, 83, noBTImg);
        } 
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        isHidden = true;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isLowPowerMode = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isLowPowerMode = true;
    }

}

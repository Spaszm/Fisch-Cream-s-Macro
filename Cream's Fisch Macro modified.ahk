#SingleInstance, force

; === Enhanced Configuration System ===
global DEBUG_MODE := false
global PERFORMANCE_LOGGING := true
global AUTO_RECOVERY := true
global ENHANCED_TRACKING := true
global ENABLE_PREDICTION := true
global PATTERN_LEARNING := true

; === Color Detection Arrays ===
global Color_Reel := {"0x522929": 10
    , "0x523733": 10
    , "0x4B2D2D": 10
    , "0x4F3329": 10
    , "0x492D29": 10
    , "0x523329": 10
    , "0x4D2D29": 10
    , "0x513329": 10}

; === Prediction System Variables ===
global lastPositions := []
global predictedDirection := 0
global predictionAccuracy := 0
global lastPredictedPosition := 0
global movementPattern := []
global patternLength := 10
global predictionOffset := 15
global lastBarSpeed := 0
global lastMoveTime := A_TickCount
global predictedPath := []
global successfulPredictions := 0
global totalPredictions := 0

; === Performance Monitoring ===
global successfulCasts := 0
global failedCasts := 0
global startTime := A_TickCount
global lastCatchTime := A_TickCount
global patternMatchCount := 0
global lastCatchPosition := 0

; === Original Display Scaling Check ===
if (A_ScreenDPI * 100 // 96 != 100) {
    Run, ms-settings:display
    msgbox, 0x1030, WARNING!!, % "Your Display Scale seems to be a value other than 100`%. This means the macro will NOT work correctly!`n`nTo change this, right-click on your Desktop -> Click 'Display Settings' -> Under 'Scale & Layout', set Scale to 100`% -> Close and Restart Roblox before starting the macro.", 60
    ExitApp
}

; === Enhanced Settings Management ===
If !FileExist("Settings.ini") {
    Msgbox,, Fisch Macro, You don't have a settings file yet. Would you like to create one? Press OK to proceed
    IniWrite, 0.05, Settings.ini, Fisch, Control
    IniWrite, 1, Settings.ini, Fisch, EnhancedTracking
    IniWrite, 1, Settings.ini, Fisch, AutoRecovery
    IniWrite, 1, Settings.ini, Fisch, EnablePrediction
    IniWrite, 15, Settings.ini, Fisch, PredictionOffset
    IniWrite, 1, Settings.ini, Fisch, PatternLearning
}

IniRead, Control, Settings.ini, Fisch, Control
If (Control = "ERROR") {
    IniWrite, 0.05, Settings.ini, Fisch, Control
    Control := "0.05"
}

Control := StrSplit(Control, "|")
If (Control[2]) {
    Msgbox The control settings are outdated.`nRestored the settings to their default values.
    IniWrite, 0.05, Settings.ini, Fisch, Control
    ExitApp
}

Control := Floor(96 + (Control[1] * 326.67))
If (!Control) {
    Log("Failed to retrieve control from settings.ini")
    Msgbox, Failed to retrieve control from settings.ini
    ExitApp
}

; === Enhanced Roblox Window Management ===
if GetRobloxHWND() {
    x := A_ScreenWidth
    y := A_ScreenHeight
    WinActivate, ahk_exe RobloxPlayerBeta.exe
    WinMove, ahk_exe RobloxPlayerBeta.exe,, x / 2 - 408, y / 2 - 408, 100, 100
    Sleep, 100
} else {
    Log("Roblox needs to be opened")
    Msgbox Roblox needs to be opened
    ExitApp
}

; === Original Coordinate System ===
Left := 246
Top := 533
Right := 569
Bottom := 533

; === Original Color Definitions ===
Color_WhiteBar := 0xF1F1F1
Color_CatchBar := 0x434B5B

; === Enhanced Helper Functions ===
CheckReelColors() {
    global Color_Reel, Left, Top, Right, Bottom
    static lastCheckTime := 0
    static lastResult := false
    
    currentTime := A_TickCount
    if (currentTime - lastCheckTime < 50) {
        return lastResult
    }
    
    for Color, Tolerance in Color_Reel {
        PixelSearch,,, Left, Top, Right, Bottom, Color, Tolerance, Fast RGB
        if (ErrorLevel = 0) {
            lastCheckTime := currentTime
            lastResult := true
            return true
        }
    }
    
    lastCheckTime := currentTime
    lastResult := false
    return false
}

UpdatePredictionData(currentPosition) {
    global lastPositions, predictedDirection, movementPattern, patternLength
    global lastMoveTime, lastBarSpeed
    
    currentTime := A_TickCount
    timeDiff := currentTime - lastMoveTime
    
    if (lastPositions.Length() > 0) {
        posDiff := currentPosition - lastPositions[lastPositions.Length()]
        lastBarSpeed := posDiff / timeDiff
    }
    
    lastMoveTime := currentTime
    lastPositions.Push(currentPosition)
    
    if (lastPositions.Length() > patternLength)
        lastPositions.RemoveAt(1)
        
    if (lastPositions.Length() >= 2) {
        movement := lastPositions[lastPositions.Length()] - lastPositions[lastPositions.Length() - 1]
        movementPattern.Push(movement)
        if (movementPattern.Length() > patternLength)
            movementPattern.RemoveAt(1)
            
        predictedDirection := lastPositions[lastPositions.Length()] > lastPositions[lastPositions.Length() - 1] ? 1 : -1
    }
}

PredictNextPosition(currentPosition) {
    global lastPositions, predictedDirection, predictionOffset, movementPattern
    global lastBarSpeed, lastMoveTime
    
    if (lastPositions.Length() < 2)
        return currentPosition
        
    timeDiff := A_TickCount - lastMoveTime
    velocityPrediction := currentPosition + (lastBarSpeed * timeDiff)
    
    patternPrediction := currentPosition
    if (movementPattern.Length() >= 3) {
        avgMovement := 0
        for i, movement in movementPattern {
            avgMovement += movement
        }
        avgMovement /= movementPattern.Length()
        patternPrediction := currentPosition + (avgMovement * 1.5)
    }
    
    finalPrediction := (velocityPrediction * 0.6) + (patternPrediction * 0.4)
    finalPrediction := Max(Left + 5, Min(Right - 5, finalPrediction))
    
    return Round(finalPrediction)
}

; === Original Main Loop with Enhancements ===
Reels()
Timer := A_TickCount

Loop {
    if (DEBUG_MODE) {
        ToolTip, % "Casts: " successfulCasts "`nFails: " failedCasts "`nPrediction Accuracy: " Round(predictionAccuracy * 100) "%", 0, 0
    }
    
    Send {down}{enter}
    
    If (A_TickCount - Timer >= 40000) {
        Reels()
        Timer := A_TickCount
    }
    
    ; Check for reel colors first
    if (CheckReelColors()) {
        Continue
    }
    
    PixelSearch,,, Left, Top, Right, Bottom, Color_WhiteBar, 20, Fast RGB
    if (ErrorLevel = 0) {
        PixelSearch,,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
        If (ErrorLevel = 0) {
            HumanMouseMove(100, 400)
            
            Loop {
                PixelSearch,,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                if (ErrorLevel = 1) {
                    Reels()
                    Tooltip
                    Timer := A_TickCount
                    UpdatePerformanceStats(true)
                    Break
                }
                
                PixelSearch,,, Left, Top, Right, Bottom, Color_WhiteBar, 20, Fast RGB
                If (ErrorLevel = 0) {
                    Loop {
                        PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                        If (ErrorLevel = 1) {
                            Break
                        } else {
                            if (ENABLE_PREDICTION) {
                                UpdatePredictionData(CurrentTarget)
                                PredictedTarget := PredictNextPosition(CurrentTarget)
                                if (Abs(PredictedTarget - CurrentTarget) < 20) {
                                    CurrentTarget := PredictedTarget
                                }
                            }
                            
                            If (CurrentTarget <= (Control + Left + Rand(-10, 10))) {
                                RandomSleep(30, 50)
                                Tooltip go left
                            } else If (CurrentTarget >= (Right - Control + Rand(-10, 10))) {
                                Click, Down
                                Tooltip go right
                                Loop {
                                    Tooltip, % A_Index
                                    PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                                    If (ErrorLevel = 0) {
                                        If (CurrentTarget <= (Right - Control + Rand(-10, 10))) {
                                            Break
                                        }
                                    } else {
                                        Break
                                    }
                                }
                                Click, Up
                                AtRight := True
                            } else {
                                PixelSearch, CurrentBarPosition,, Left, Top, Right, Bottom, Color_WhiteBar, 20, Fast RGB
                                If (ErrorLevel = 0) {
                                    PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                                    CurrentBarPosition := CurrentBarPosition + (Control / 2)
                                    Distance := CurrentTarget - CurrentBarPosition
                                    Percentage := (Distance / Control) * 100
                                    Tooltip % Percentage "x" Distance "x" CurrentBarPosition
                                    if (Percentage >= 0) {
                                        Val := Floor(140 + ((440 - 140) * (Percentage / 100)))
                                        Tooltip % Val
                                        If (Val = 0) {
                                            Reels(30)
                                        } else {
                                            Reels(Val)
                                        }
                                    } else {
                                        Val := Floor(-((100 - 0) * (Percentage / 100)))
                                        if (Val < 30) {
                                            Tooltip, I'd click
                                            Reels(30)
                                        } else {
                                            Tooltip % Val - 30 " sleep time"
                                            RandomSleep(Val - 40, Val - 20)
                                        }
                                    }
                                } else {
                                    Break
                                }
                            }
                        }
                    }
                    PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                    If (CurrentTarget > 408) {
                        AtRight := True
                    }
                } else {
                    PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                    If (ErrorLevel = 0) {
                        If (CurrentTarget <= (Control + Left + Rand(-10, 10))) {
                            RandomSleep(30, 50)
                            Tooltip go left
                        } else If (CurrentTarget >= (Right - Control - Rand(-10, 10))) {
                            Click, Down
                            Tooltip go right
                            Loop {
                                Tooltip, % A_Index " 2"
                                PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                                If (ErrorLevel = 0) {
                                    If (CurrentTarget <= (Right - Control + Rand(-10, 10))) {
                                        Break
                                    }
                                } else {
                                    Break
                                }
                            }
                            Click, Up
                        } else {
                            If (AtRight && (CurrentTarget >= 408)) {
                                RandomSleep(90, 110)
                                AtRight := false
                            } else {
                                Tooltip, I reel 300
                                Reels(300, True)
                            }
                        }
                        PixelSearch, CurrentTarget,, Left, Top, Right, Bottom, Color_CatchBar, 3, Fast RGB
                        If (CurrentTarget > 408) {
                            AtRight := True
                        }
                    }
                }
            }
        }
    }
}

$Space::ExitApp

; === Original Functions with Minor Enhancements ===
Reels(x := 0, Stop := false) {
    If (!x) {
        RandomSleep(1800, 2200)
        Click, Down, 100, 400
        RandomSleep(1800, 2200)
        Click, Up, 100, 400
        RandomSleep(1800, 2200)
        Send \
        Return True
    }
    
    Whitebar := false
    Click, Down
    Timer := A_TickCount
    
    Loop {
        If (Stop) {
            if (CheckReelColors()) {
                Whitebar := true
                Break
            }
            PixelSearch,,, 246, 533, 569, 533, 0xF1F1F1, 20, Fast RGB
            If (ErrorLevel = 0) {
                Whitebar := true
                Break
            }
        }
        If (A_TickCount - Timer >= x) {
            Break
        }
    }
    
    Click, Up
    Return Whitebar
}

GetRobloxHWND() {
    if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe"))
        return hwnd
}

Rand(min, max) {
    Random, out, min, max
    Return out
}

RandomSleep(MinTime, MaxTime) {
    Random, SleepTime, MinTime, MaxTime
    Sleep, SleepTime
}

HumanMouseMove(TargetX, TargetY) {
    MouseGetPos, StartX, StartY
    Distance := Sqrt((TargetX - StartX) ** 2 + (TargetY - StartY) ** 2)
    Duration := Max(5, Distance / 3)
    Random, DurationRand, -10, 10
    Duration += DurationRand
    MouseMove, TargetX, TargetY, Duration
}

Log(message) {
    if (DEBUG_MODE) {
        FormatTime, TimeStamp, %A_Now%, yyyy-MM-dd HH:mm:ss
        FileAppend, %TimeStamp%: %message%`n, fishing_log.txt
    }
}

UpdatePerformanceStats(success := true) {
    global
    if (success) {
        successfulCasts++
        lastCatchTime := A_TickCount
    } else {
        failedCasts++
    }
} ; === IMPROVED, AND OPTIMIZED. 10 LINES LESS? WOW!!! now 410.

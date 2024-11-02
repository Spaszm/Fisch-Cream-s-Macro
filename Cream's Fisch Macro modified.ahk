#SingleInstance, force

; === Enhanced Configuration System ===
global DEBUG_MODE := false
global PERFORMANCE_LOGGING := true
global AUTO_RECOVERY := true
global ENHANCED_TRACKING := true
global ENABLE_PREDICTION := true
global PATTERN_LEARNING := true

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

; Read settings
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
    
    if !WinActive("ahk_exe RobloxPlayerBeta.exe") {
        Log("Failed to activate Roblox window")
        Msgbox, Failed to activate Roblox window
        ExitApp
    }
} else {
    Log("Roblox needs to be opened")
    Msgbox Roblox needs to be opened
    ExitApp
}

; === Enhanced Coordinate System ===
global Left := 246
global Top := 533
global Right := 569
global Bottom := 533
global SearchWidth := Right - Left
global SearchHeight := 4

; === Color Definitions ===
global Color_WhiteBar := 0xF1F1F1
global Color_CatchBar := 0x434B5B

; === New Prediction System Functions ===
UpdatePredictionData(currentPosition) {
    global lastPositions, predictedDirection, movementPattern, patternLength, lastMoveTime, lastBarSpeed
    
    currentTime := A_TickCount
    timeDiff := currentTime - lastMoveTime
    
    if (lastPositions.Length() > 0) {
        posDiff := currentPosition - lastPositions[lastPositions.Length()]
        lastBarSpeed := posDiff / timeDiff
    }
    
    lastMoveTime := currentTime
    
    lastPositions.Push(currentPosition)
    if (lastPositions.Length() > patternLength) {
        lastPositions.RemoveAt(1)
    }
    
    if (lastPositions.Length() >= 2) {
        movement := lastPositions[lastPositions.Length()] - lastPositions[lastPositions.Length() - 1]
        movementPattern.Push(movement)
        if (movementPattern.Length() > patternLength) {
            movementPattern.RemoveAt(1)
        }
        
        predictedDirection := lastPositions[lastPositions.Length()] > lastPositions[lastPositions.Length() - 1] ? 1 : -1
    }
}

; === Enhanced Prediction and Detection Functions ===
PredictNextPosition(currentPosition) {
    global lastPositions, predictedDirection, predictionOffset, movementPattern, lastBarSpeed, lastMoveTime
    
    if (lastPositions.Length() < 2)
        return currentPosition
    
    timeSinceLastMove := A_TickCount - lastMoveTime
    velocityPrediction := currentPosition + (lastBarSpeed * timeSinceLastMove)
    
    ; Pattern-based prediction
    patternPrediction := currentPosition
    if (movementPattern.Length() >= 3) {
        avgMovement := 0
        for i, movement in movementPattern {
            avgMovement += movement
        }
        avgMovement /= movementPattern.Length()
        patternPrediction := currentPosition + (avgMovement * 1.5)
    }
    
    ; Combine predictions
    finalPrediction := (velocityPrediction * 0.6) + (patternPrediction * 0.4)
    
    ; Ensure prediction stays within bounds
    finalPrediction := Max(Left + 5, Min(Right - 5, finalPrediction))
    
    return Round(finalPrediction)
}

ValidatePrediction(predictedPos, actualPos) {
    global predictionAccuracy, successfulPredictions, totalPredictions
    error := Abs(predictedPos - actualPos)
    totalPredictions++
    
    if (error < 20) {
        successfulPredictions++
        predictionAccuracy += 0.1
    } else {
        predictionAccuracy -= 0.05
    }
    
    predictionAccuracy := Max(0, Min(1, predictionAccuracy))
    return error < 20
}

AnalyzePattern() {
    global movementPattern, patternLength, patternMatchCount
    
    if (movementPattern.Length() < patternLength)
        return false
        
    patterns := {}
    maxCount := 0
    dominantPattern := ""
    
    Loop, % movementPattern.Length() - 2 {
        sequence := movementPattern[A_Index] . "," . movementPattern[A_Index + 1] . "," . movementPattern[A_Index + 2]
        patterns[sequence] := (patterns[sequence] ? patterns[sequence] + 1 : 1)
        
        if (patterns[sequence] > maxCount) {
            maxCount := patterns[sequence]
            dominantPattern := sequence
        }
    }
    
    if (maxCount > 2) {
        patternMatchCount++
        return dominantPattern
    }
    return false
}

; === Enhanced Detection System ===
DetectBarPosition(color, variation := 3) {
    global Left, Top, Right, Bottom, ENHANCED_TRACKING
    
    if (ENHANCED_TRACKING) {
        positions := []
        Loop, 5 {
            offset := (A_Index - 3) * 2
            PixelSearch, foundX, foundY, Left, Top + offset, Right, Bottom + offset, color, variation, Fast RGB
            if (ErrorLevel = 0) {
                positions.Push(foundX)
            }
        }
        
        if (positions.Length() > 0) {
            Sort positions
            if (positions.Length() >= 3) {
                positions.RemoveAt(1)
                positions.RemoveAt(positions.Length())
            }
            
            sum := 0
            for index, value in positions {
                sum += value
            }
            return Floor(sum / positions.Length())
        }
    } else {
        PixelSearch, foundX, foundY, Left, Top, Right, Bottom, color, variation, Fast RGB
        if (ErrorLevel = 0) {
            return foundX
        }
    }
    return 0
}

; === Main Enhanced Loop ===
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
    
    currentBarPos := DetectBarPosition(Color_WhiteBar, 20)
    if (currentBarPos) {
        catchBarPos := DetectBarPosition(Color_CatchBar, 3)
        If (catchBarPos) {
            HumanMouseMove(100, 400)
            
            Loop {
                catchBarPos := DetectBarPosition(Color_CatchBar, 3)
                if (!catchBarPos) {
                    Reels()
                    if (DEBUG_MODE) {
                        Tooltip
                    }
                    Timer := A_TickCount
                    UpdatePerformanceStats(true)
                    Break
                }
                
                currentBarPos := DetectBarPosition(Color_WhiteBar, 20)
                If (currentBarPos) {
                    Loop {
                        catchBarPos := DetectBarPosition(Color_CatchBar, 3)
                        If (!catchBarPos) {
                            Break
                        }
                        
                        if (ENABLE_PREDICTION) {
                            UpdatePredictionData(catchBarPos)
                            predictedPos := PredictNextPosition(catchBarPos)
                            
                            if (ValidatePrediction(lastPredictedPosition, catchBarPos)) {
                                catchBarPos := predictedPos
                            }
                            
                            lastPredictedPosition := predictedPos
                        }
                        
                        If (catchBarPos <= (Control + Left + Rand(-10, 10))) {
                            RandomSleep(30, 50)
                            if (DEBUG_MODE) {
                                Tooltip go left
                            }
                        } else If (catchBarPos >= (Right - Control + Rand(-10, 10))) {
                            Click, Down
                            if (DEBUG_MODE) {
                                Tooltip go right
                            }
                            Loop {
                                if (DEBUG_MODE) {
                                    Tooltip, % A_Index
                                }
                                catchBarPos := DetectBarPosition(Color_CatchBar, 3)
                                If (catchBarPos) {
                                    If (catchBarPos <= (Right - Control + Rand(-10, 10))) {
                                        Break
                                    }
                                } else {
                                    Break
                                }
                            }
                            Click, Up
                            AtRight := True
                        } else {
                            If (AtRight && (catchBarPos >= 408)) {
                                RandomSleep(90, 110)
                                AtRight := false
                            } else {
                                if (DEBUG_MODE) {
                                    Tooltip, I reel 300
                                }
                                Reels(300, True)
                            }
                        }
                        
                        if (PATTERN_LEARNING && AnalyzePattern()) {
                            predictionOffset := Max(10, Min(20, predictionOffset + (predictionAccuracy * 5)))
                        }
                    }
                }
            }
        }
    }
}

$Space::ExitApp

; === Enhanced Original Functions ===
Reels(x := 0, Stop := false) {
    global
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
            if (ENHANCED_TRACKING) {
                Whitebar := DetectBarPosition(0xF1F1F1, 20)
            } else {
                PixelSearch,,, 246, 533, 569, 533, 0xF1F1F1, 20, Fast RGB
                Whitebar := (ErrorLevel = 0)
            }
            If (Whitebar) {
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
    return 0
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
} ; WOW, NOW WITH 422 LINES

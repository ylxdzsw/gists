function regen(t)
    local cv1 = readInteger(0x93CCB120)
    local cv2 = readInteger(0x93CCB0E4)
    if cv1 < 34 then
        writeInteger(0x93CCB120, cv1 + 1)
    end
    if cv2 < 4 then
        writeInteger(0x93CCB0E4, cv2 + 1)
    end
end

function timerOn()
    t = createTimer(nil)
    t.Interval = 500
    t.OnTimer = regen
    t.Enabled = true
end

[enable] 
luacall(timerOn()) 
[disable] 
luacall(t.destroy()) 

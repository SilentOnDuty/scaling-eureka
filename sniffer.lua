-- REDNET SNIFFER v2026 - Enhanced (shows private/direct vs broadcast)
-- Listens to ALL rednet traffic including "private" send() messages

local VERSION = "2026-enhanced"
local LOG_FILE = "sniff_log.txt"
local MODEM_SIDE = "back"   -- ← change if your modem is on another side

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.lime)
print("REDNET SNIFFER " .. VERSION)
term.setTextColor(colors.gray)
print("P = pause   S = save current   R = replay last   L = list slots")
print("Q = quit    F = toggle filter (not implemented yet)\n")

rednet.open(MODEM_SIDE)

local paused = false
local currentMsg, currentSender, currentDist, currentType = nil, nil, nil, nil
local saved = {} for i=0,15 do saved[i] = nil end   -- slots 0-F

local function logPacket(sender, dist, msgType, msg)
    local f = fs.open(LOG_FILE, "a")
    if f then
        f.writeLine(string.format("[%s] %d | dist %.1f | %s | %s",
            os.date("%H:%M:%S"), sender, dist or 0, msgType, textutils.serialize(msg)))
        f.close()
    end
end

local function isTurtle(msg)
    local s = textutils.serialize(msg):lower()
    return s:find("turtle") or s:find("fuel") or s:find("dig") or s:find("quarry")
end

local function drawUI()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.lime)
    print("REDNET SNIFFER " .. VERSION .. (paused and " [PAUSED]" or ""))
    term.setTextColor(colors.gray)
    print("P=Pause  S=Save  R=Replay  L=List  Q=Quit\n")

    if currentMsg then
        local color = colors.white
        if currentDist then
            if currentDist < 10 then color = colors.red
            elseif currentDist < 30 then color = colors.orange
            elseif currentDist < 60 then color = colors.yellow end
        end
        
        term.setTextColor(color)
        print(string.format("From %d @ %.1f blocks   Type: %s", 
            currentSender or "?", currentDist or 0, currentType or "unknown"))
        
        term.setTextColor(isTurtle(currentMsg) and colors.orange or colors.white)
        print(textutils.serialize(currentMsg))
    else
        print("Waiting for packets...")
    end

    term.setCursorPos(1,18)
    term.setTextColor(colors.gray)
    print("Saved packets (0-F):")
    for i=0,15 do
        term.setCursorPos(1 + i*3, 19)
        term.setTextColor(saved[i] and colors.lime or colors.gray)
        write(string.format("%X", i))
    end
end

drawUI()

while true do
    local event, p1, p2, p3, p4, p5 = os.pullEvent()

    if event == "modem_message" and not paused then
        local side, channel, replyChannel, message, distance = p1, p2, p3, p4, p5

        currentSender = replyChannel
        currentMsg    = message
        currentDist   = distance
        
        -- Detect broadcast vs direct/private
        if channel == 65535 then
            currentType = "BROADCAST"
        else
            currentType = "DIRECT (to " .. channel .. ")"
        end

        logPacket(replyChannel, distance, currentType, message)
        drawUI()

    elseif event == "key" then
        local key = p1
        
        if key == keys.p then
            paused = not paused
            drawUI()
            
        elseif key == keys.q or key == keys.escape then
            print("Exiting...")
            rednet.close(MODEM_SIDE)
            break
            
        elseif key == keys.s and currentMsg then
            for i=0,15 do
                if not saved[i] then
                    saved[i] = {
                        sender = currentSender,
                        dist   = currentDist,
                        type   = currentType,
                        msg    = currentMsg
                    }
                    print("Saved to slot " .. string.format("%X", i))
                    drawUI()
                    break
                end
            end
            
        elseif key == keys.r and currentMsg then
            print("Replaying last packet as broadcast...")
            local copy = textutils.unserialize(textutils.serialize(currentMsg)) -- deep copy
            if copy and type(copy) == "table" and copy.nMessageID then
                copy.nMessageID = math.random(1, 2147483647) -- avoid duplicate rejection
            end
            rednet.broadcast(copy)
            print("Replayed.")
            
        elseif key == keys.l then
            print("Saved slots:")
            for i=0,15 do
                if saved[i] then
                    local preview = textutils.serialize(saved[i].msg):sub(1,40) .. "..."
                    print(string.format("%X: %s | From %d @ %.1f - %s",
                        i, saved[i].type, saved[i].sender, saved[i].dist or 0, preview))
                end
            end
        end

    elseif event == "mouse_click" then
        local button, x, y = p1, p2, p3
        if y == 19 and x >= 1 and x <= 48 then
            local slot = math.floor((x-1)/3)
            if saved[slot] then
                currentSender = saved[slot].sender
                currentDist   = saved[slot].dist
                currentType   = saved[slot].type
                currentMsg    = saved[slot].msg
                drawUI()
                print("Loaded slot " .. string.format("%X", slot))
            end
        end
    end
end

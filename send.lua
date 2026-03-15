-- sendit.lua — quick rednet broadcaster / tester
-- Type target ID (or 'b' for broadcast), then message

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.lime)
print("SENDIT v1 — rednet broadcaster")
term.setTextColor(colors.white)
print("Target: number = specific ID, 'b' = broadcast")
print("Type 'exit' to quit\n")

rednet.open("back")  -- change side if needed

while true do
    term.setCursorPos(1, term.getSize()-2)
    term.clearLine()
    term.setTextColor(colors.lime)
    write("Target: ")
    term.setTextColor(colors.white)
    local targetInput = read():lower()

    if targetInput == "exit" then
        print("Exiting...")
        break
    end

    local target
    if targetInput == "b" then
        target = nil  -- broadcast
        print("Broadcast mode selected")
    else
        target = tonumber(targetInput)
        if not target then
            print("Invalid target — use number or 'b'")
            sleep(1)
            goto continue
        end
        print("Sending to #" .. target)
    end

    term.setCursorPos(1, term.getSize()-1)
    term.clearLine()
    term.setTextColor(colors.lime)
    write("Message: ")
    term.setTextColor(colors.white)
    local message = read()

    if message == "" then
        print("Empty message — skipped")
        goto continue
    end

    -- Optional: wrap in table for structure
    local payload = {
        from = os.getComputerID(),
        text = message,
        time = os.date("%H:%M:%S")
    }

    if target then
        rednet.send(target, payload)
        print("Sent to #" .. target)
    else
        rednet.broadcast(payload)
        print("Broadcasted to everyone")
    end

    ::continue::
    sleep(0.3)
end

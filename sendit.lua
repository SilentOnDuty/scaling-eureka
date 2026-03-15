term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.lime)
print("SENDIT — rednet broadcaster")
term.setTextColor(colors.white)
print("Target: number = ID, 'b' = broadcast")
print("Type 'exit' to quit\n")

rednet.open("back")

while true do
    term.setCursorPos(1, term.getSize()-2)
    term.clearLine()
    term.setTextColor(colors.lime)
    write("Target: ")
    term.setTextColor(colors.white)
    local t = read():lower()

    if t == "exit" then
        print("Exiting...")
        break
    end

    local target = t == "b" and nil or tonumber(t)
    if not target and t ~= "b" then
        print("Invalid — use number or 'b'")
        sleep(0.8)
        goto next
    end

    term.setCursorPos(1, term.getSize()-1)
    term.clearLine()
    term.setTextColor(colors.lime)
    write("Message: ")
    term.setTextColor(colors.white)
    local msg = read()

    if msg == "" then goto next end

    local payload = {from=os.getComputerID(), text=msg, time=os.date("%H:%M:%S")}

    if target then
        rednet.send(target, payload)
        print("Sent to #"..target)
    else
        rednet.broadcast(payload)
        print("Broadcasted")
    end

    ::next::
    sleep(0.3)
end

local tossam = require("tossam")
local clock = os.clock

local MSG_SETUP_PARENT = 1
local MSG_SETUP_FINISH = 3
local MSG_REQ_TEMP = 4
local MSG_SEND_TEMP = 6

local mote

function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

function connectAndSetMsg()
	mote = tossam.connect {
	  protocol = "sf",
	  host     = "localhost",
	  port     = 9002,
	  nodeid   = 1
	}

    if not(mote) then print("Connection error!"); return(1); end

    mote:register [[
      nx_struct msg_serial [145] {
        nx_uint8_t id;
        nx_uint16_t source;
        nx_uint16_t target;   
        nx_uint8_t  d8[4];
        nx_uint16_t d16[4];
        nx_uint32_t d32[2];
      };
    ]]
end

function finishConnection()
	mote:unregister()
    mote:close()
end

function receiveTempMsgFrom(sourceId)
	local stat, msg, emsg
	local timeout = 5
	local t0 = clock()
  	while clock() - t0 <= timeout do
		stat, msg, emsg = pcall(function() return mote:receive() end)
		if stat then
	        if msg then
	        	if msg.id == MSG_SEND_TEMP and msg.source == sourceId then
	                print("Source: ".. msg.source)
	                print("TEMPERATURE: ", unpack(msg.d16))
	                return msg.d16
	            end
	        else
	            if emsg == "closed" then
	                print("\nConnection closed!")
	                connectAndSetMsg()
					finishConnection()
	            else
	                print("\nTimeout!")
	                connectAndSetMsg()
					finishConnection()
	            end
	        end
	    else
	        print("\nreceive() got an error:"..msg)
            connectAndSetMsg()
			finishConnection()
	    end
	end
end

function sendMoteSetupMessage(mote_id, mote_childs)
	len = 0
	for childCount = 1, #mote_childs do
	  	if mote_childs[childCount] ~= 0 then
	  		len = len + 1
	  	end
	end

	msg = {
	    id        = MSG_SETUP_PARENT,
	    source    = 0,
	    target    = 0,
	    d8        = {mote_id, len, 0, 0},
	    d16        = mote_childs,
	    d32        = {0, 0}
    }

	mote:send(msg,145)
end

function notifyNodesFinishSetup()
	msg = {
	    id        = MSG_SETUP_FINISH,
	    source    = 0,
	    target    = 0,
	    d8        = {0, 0, 0, 0},
	    d16        = {0, 0, 0, 0},
	    d32        = {0, 0}
    }

	mote:send(msg,145)
end

function sendMoteTempReqMessage(mote_id, index)
	msg = {
	    id        = MSG_REQ_TEMP,
	    source    = 0,
	    target    = 0,
	    d8        = {mote_id, index, 0, 0},
	    d16        = {0, 0, 0, 0},
	    d32        = {0, 0}
    }

	mote:send(msg,145)
end
--[[
while not(exit) do
    sendMoteSetupMessage(mote, 11, {21, 12, 22, 0})
	print("1")
	sleep(3)
    sendMoteSetupMessage(mote, 13, {23, 24, 14, 0})
	print("2")
	sleep(3)
    sendMoteSetupMessage(mote, 15, {25, 26, 16, 0})
	print("3")
	sleep(3)
    sendMoteSetupMessage(mote, 17, {27, 28, 18, 0})
	print("4")
	sleep(3)
    sendMoteSetupMessage(mote, 31, {41, 32, 42, 0})
	print("5")
	sleep(3)
    sendMoteSetupMessage(mote, 33, {43, 44, 34, 0})
	print("6")
	sleep(3)
    sendMoteSetupMessage(mote, 35, {45, 36, 46, 0})
	print("5")
	sleep(3)
    sendMoteSetupMessage(mote, 37, {47, 48, 38, 0})
	print("6")
	sleep(3)
	
	notifyNodesFinishSetup(mote)
	print("Finish")
	sleep(5)

	local index = 0
	sendMoteTempReqMessage(mote, 13, index)
	index = index + 1
	print("Send temp 0 request")

    while (mote) do

        local stat, msg, emsg = pcall(function() return mote:receive() end)
        if stat then
            if msg then
            	if msg.id == MSG_SEND_TEMP and msg.source == 13 then
            		print("--------SEND TEMP MESSAGE ---------")
	                print("Source: ".. msg.source)
	                print("TEMPERATURE: ",unpack(msg.d16))

					sleep(5)
					sendMoteTempReqMessage(mote, 13, index)
					index = index + 1
					print("Send temp " .. index .. " request")
            	else 
	                print("------------------------------")
	                print("msgID: " .. msg.id, "Source: ".. msg.source, "Target: ".. msg.target)
	                print("d8:",unpack(msg.d8))
	                print("d16:",unpack(msg.d16))
	                print("d32:",unpack(msg.d32))
	            end
            else
                if emsg == "closed" then
                    print("\nConnection closed!")
                    exit = true
                    break
                else
                    print("\nTimeout!")
                end
            end
        else
            print("\nreceive() got an error:"..msg)
            exit = true
            break
        end
    end 
end
]]--
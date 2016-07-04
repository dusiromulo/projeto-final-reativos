local moteOp = require("mote_operator")

local roomsFilename = "sdl-src/assets/rooms.txt"

local requestFilename = "sdl-src/temp/request"
local responseFilename = "sdl-src/temp/response"
local lockFilename = "sdl-src/temp/lock"

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

-- MAIN CODE

if (moteOp) then
	if connectAndSetMsg() == 1 then
		return
	else

		roomsFile = io.open(roomsFilename, "r")
		io.input(roomsFile)

		local parentChildsMap = {}
		for line in io.lines() do
			local parentNode = 0
			local childNodes = {0, 0, 0, 0}

			local splitChilds = split(line, " ")

			for childCount = 1, #splitChilds do
				if childCount > 5 then
					parentChildsMap[parentNode] = childNodes
					break
				end

				if childCount == 1 then
					parentNode = tonumber(splitChilds[childCount])
				else
					childNodes[childCount-1] = tonumber(splitChilds[childCount])
				end
			end

			sendMoteSetupMessage(parentNode, childNodes)
			sleep(3)
		end

		io.close(roomsFile)

		notifyNodesFinishSetup()

		local flag = true
		local indexesNodes = {}
		while flag do
			lockfile = io.open(lockFilename)

			if lockfile then
				parenteNodeRequest = 0
				requestfile = io.open(requestFilename)
				io.input(requestfile)

				for line in io.lines() do
					parenteNodeRequest = tonumber(line)
				end
				
				io.close(requestfile)

				if not indexesNodes[parenteNodeRequest] then
					indexesNodes[parenteNodeRequest] = 0
				else
					indexesNodes[parenteNodeRequest] = indexesNodes[parenteNodeRequest] + 1

				end
				sendMoteTempReqMessage(parenteNodeRequest, indexesNodes[parenteNodeRequest])

				data = receiveTempMsgFrom(parenteNodeRequest)
				
				responseFile = io.open(responseFilename, "w")
				io.output(responseFile)
				io.write(tostring(data[1]))
				io.close(responseFile)

				io.close(lockfile)
				os.remove(lockFilename)
			end

			sleep(0.5)
		end
	end
end
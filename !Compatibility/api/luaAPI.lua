--Cache global variables
local assert = assert
local error = error
local geterrorhandler = geterrorhandler
local pairs = pairs
local pcall = pcall
local tostring = tostring
local type = type
local unpack = unpack
local format = string.format
local getn, tinsert = table.getn, table.insert

function select(n, ...)
	assert(type(n) == "number" or type(n) == "string", format("bad argument #1 to 'select' (number expected, got %s)", n and type(n) or "no value"))

	if type(n) == "string" and n == "#" then
		if type(arg) == "table" then
			return getn(arg)
		else
			return 1
		end
	end

	local temp = {}

	for i = n, getn(arg) do
		tinsert(temp, arg[i])
	end

	return unpack(temp)
end

function string.join(delimiter, ...)
	assert(type(delimiter) == "string" or type(delimiter) == "number", format("bad argument #1 to 'join' (string expected, got %s)", delimiter and type(delimiter) or "no value"))

    local size = getn(arg)
    if size == 0 then
        return ""
    end

    local text = arg[1]
    for i = 2, size do
        text = text..delimiter..arg[i]
    end

    return text
end
strjoin = string.join

function table.wipe(t)
	assert(type(t) == "table", format("bad argument #1 to 'wipe' (table expected, got %s)", t and type(t) or "no value"))

	for k in pairs(t) do
		t[k] = nil
	end

	return t
end
wipe = table.wipe

local LOCAL_ToStringAllTemp = {}
function tostringall(...)
    local n = getn(arg)
    -- Simple versions for common argument counts
    if (n == 1) then
        return tostring(arg[1])
    elseif (n == 2) then
        return tostring(arg[1]), tostring(arg[2])
    elseif (n == 3) then
        return tostring(arg[1]), tostring(arg[2]), tostring(arg[3])
    elseif (n == 0) then
        return
    end

    local needfix
    for i = 1, n do
        local v = arg[i]
        if (type(v) ~= "string") then
            needfix = i
            break
        end
    end
    if (not needfix) then return unpack(arg) end

    wipe(LOCAL_ToStringAllTemp)
    for i = 1, needfix - 1 do
        LOCAL_ToStringAllTemp[i] = arg[i]
    end
    for i = needfix, n do
        LOCAL_ToStringAllTemp[i] = tostring(arg[i])
    end
    return unpack(LOCAL_ToStringAllTemp)
end

local LOCAL_PrintHandler = function(...)
	DEFAULT_CHAT_FRAME:AddMessage(strjoin(" ", tostringall(unpack(arg))))
end

function setprinthandler(func)
	if (type(func) ~= "function") then
		error("Invalid print handler")
	else
		LOCAL_PrintHandler = func
	end
end

function getprinthandler() return LOCAL_PrintHandler end

local function print_inner(...)
	local ok, err = pcall(LOCAL_PrintHandler, unpack(arg))
	if (not ok) then
		local func = geterrorhandler()
		func(err)
	end
end

function print(...)
	pcall(print_inner, unpack(arg))
end

SLASH_PRINT1 = "/print"
SlashCmdList["PRINT"] = print
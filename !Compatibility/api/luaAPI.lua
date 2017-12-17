--Cache global variables
local assert = assert
local error = error
local geterrorhandler = geterrorhandler
local loadstring = loadstring
local pairs = pairs
local pcall = pcall
local tostring = tostring
local type = type
local unpack = unpack
local ceil, floor = math.ceil, math.floor
local find, format, gfind, gsub, sub = string.find, string.format, string.gfind, string.gsub, string.sub
local getn, setn, tinsert = table.getn, table.setn, table.insert

local escapeSequences = {
	["\a"] = "\\a", -- Bell
	["\b"] = "\\b", -- Backspace
	["\t"] = "\\t", -- Horizontal tab
	["\n"] = "\\n", -- Newline
	["\v"] = "\\v", -- Vertical tab
	["\f"] = "\\f", -- Form feed
	["\r"] = "\\r", -- Carriage return
	["\\"] = "\\\\", -- Backslash
	["\""] = "\\\"", -- Quotation mark
	["|"] = "||",
	[" "] = "%s",

	[" "] = "%s",
	["!"] = "\\!",
	["#"] = "\\#",
	["$"] = "\\$",
	["%"] = "\\%",
	["&"] = "\\&",
	["'"] = "\\'",
	["("] = "\\(",
	[")"] = "\\)",
	["*"] = "\\*",
	["+"] = "\\+",
	[","] = "\\,",
	["-"] = "\\-",
	["."] = "\\.",
	["/"] = "\\/"
}

math.huge = 1/0
string.gmatch = gfind

function difftime(time2, time1)
	assert(type(time2) == "number", format("bad argument #1 to 'difftime' (number expected, got %s)", time2 and type(time2) or "no value"))
	assert(not time1 or type(time1) == "number", format("bad argument #2 to 'difftime' (number expected, got %s)", time1 and type(time1) or "no value"))

	return time1 and time2 - time1 or time2
end

function select(n, ...)
	assert(type(n) == "number" or (type(n) == "string" and n == "#"), format("bad argument #1 to 'select' (number expected, got %s)", n and type(n) or "no value"))

	if type(n) == "string" then
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

function math.modf(i)
	assert(type(i) == "number", format("bad argument #1 to 'modf' (number expected, got %s)", i and type(i) or "no value"))

	local int = i >= 0 and floor(i) or ceil(i)

	return int, i - int
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

function string.match(str, pattern, index)
	assert(type(str) == "string" or type(str) == "number", format("bad argument #1 to 'match' (string expected, got %s)", str and type(str) or "no value"))
	assert(type(pattern) == "string" or type(pattern) == "number", format("bad argument #2 to 'match' (string expected, got %s)", pattern and type(pattern) or "no value"))

	str = type(str) == "number" and tostring(str) or str
	pattern = type(pattern) == "number" and tostring(pattern) or pattern

	return gfind(index and sub(str, index) or str, pattern)()
end
strmatch = string.match

function string.split(delimiter, str)
	assert(type(delimiter) == "string" or type(str) == "number", format("bad argument #1 to 'split' (string expected, got %s)", delimiter and type(delimiter) or "no value"))
	assert(type(str) == "string", format("bad argument #2 to 'split' (string expected, got %s)", str and type(str) or "no value"))

	local fields = {}
	local pattern = format("([^%s]+)", delimiter)

	str = type(str) == "number" and tostring(str) or str
	gsub(str, pattern, function(c) fields[getn(fields) + 1] = c end)

	return unpack(fields)
end
strsplit = string.split

function string.trim(str, chars)
	assert(type(str) == "string" or type(str) == "number", format("bad argument #1 to 'trim' (string expected, got %s)", str and type(str) or "no value"))
	assert(not type(chars) == "string" or type(chars) == "number", format("bad argument #2 to 'trim' (string expected, got %s)", chars and type(chars) or "no value"))

	str = type(str) == "number" and tostring(str) or str

	if chars then
		chars = type(chars) == "number" and tostring(chars) or chars

		local tokens = {}

		for token in gfind(chars, "[%z\1-\255\"\\]") do
			tinsert(tokens, token)
		end

		local pattern = ""
		local size = getn(tokens)

		for i = 1, size do
			pattern = pattern..(escapeSequences[tokens[i]] or tokens[i]).."+"

			if size > 1 and i < size then
				pattern = pattern.."|"
			end
		end

		patternStart = "^["..pattern.."](.-)$"
		patternEnd = "^(.-)["..pattern.."]$"
		patternStart = loadstring("return \""..patternStart.."\"")()
		patternEnd = loadstring("return \""..patternEnd.."\"")()

		local trimed, x, y = 1
		while trimed >= 1 do
			str, x = gsub(str, patternStart, "%1")
			str, y = gsub(str, patternEnd, "%1")
			trimed = x + y
		end

		return str
	else
		-- remove leading/trailing [space][tab][return][newline]
		return string.gsub(str, "^%s*(.-)%s*$", "%1")
	end
end
strtrim = string.trim

function table.wipe(t)
	assert(type(t) == "table", format("bad argument #1 to 'wipe' (table expected, got %s)", t and type(t) or "no value"))

	for k in pairs(t) do
		t[k] = nil
	end

	if getn(t) ~= 0 then
		setn(t, 0)
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
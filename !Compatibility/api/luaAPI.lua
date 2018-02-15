--Cache global variables
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

math.huge = 1/0
string.gmatch = string.gfind

function difftime(time2, time1)
	if type(time2) ~= "number" then
		error(format("bad argument #1 to 'difftime' (number expected, got %s)", time2 and type(time2) or "no value"), 2)
	elseif time1 and type(time1) ~= "number" then
		error(format("bad argument #2 to 'difftime' (number expected, got %s)", time1 and type(time1) or "no value"), 2)
	end

	return time1 and time2 - time1 or time2
end

function select(n, ...)
	if not (type(n) == "number" or (type(n) == "string" and n == "#")) then
		error(format("bad argument #1 to 'select' (number expected, got %s)", n and type(n) or "no value"), 2)
	end

	if type(n) == "string" then
		return getn(arg)
	end

	if n == 1 then
		return unpack(arg)
	end

	local args = {}

	for i = n, getn(arg) do
		args[i-n+1] = arg[i]
	end

	return unpack(args)
end

function math.modf(i)
	if type(i) ~= "number" then
		error(format("bad argument #1 to 'modf' (number expected, got %s)", i and type(i) or "no value"), 2)
	end

	local int = i >= 0 and floor(i) or ceil(i)

	return int, i - int
end

function string.join(delimiter, ...)
	if type(delimiter) ~= "string" and type(delimiter) ~= "number" then
		error(format("bad argument #1 to 'join' (string expected, got %s)", delimiter and type(delimiter) or "no value"), 2)
	end

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
	if type(str) ~= "string" and type(str) ~= "number" then
		error(format("bad argument #1 to 'match' (string expected, got %s)", str and type(str) or "no value"), 2)
	elseif type(pattern) ~= "string" and type(pattern) ~= "number" then
		error(format("bad argument #2 to 'match' (string expected, got %s)", pattern and type(pattern) or "no value"), 2)
	elseif index and type(index) ~= "number" and (type(index) ~= "string" or index == "") then
		error(format("bad argument #3 to 'match' (number expected, got %s)", index and type(index) or "no value"), 2)
	end

	str = type(str) == "number" and tostring(str) or str
	pattern = type(pattern) == "number" and tostring(pattern) or pattern

	if type(index) == "string" then
		index = index ~= "" and tonumber(index) or nil
	end

	local i1, i2, match, match2 = find(str, pattern, index)

	if not match and i2 and i2 >= i1 then
		return sub(str, i1, i2)
	elseif match2 then
		return select(3, find(str, pattern, index))
	end

	return match
end
strmatch = string.match

function string.split(delimiter, str)
	if type(delimiter) ~= "string" and type(delimiter) ~= "number" then
		error(format("bad argument #1 to 'split' (string expected, got %s)", delimiter and type(delimiter) or "no value"), 2)
	elseif type(str) ~= "string" and type(str) ~= "number" then
		error(format("bad argument #2 to 'split' (string expected, got %s)", str and type(str) or "no value"), 2)
	end

	str = type(str) == "number" and tostring(str) or str

	local fields = {}
	gsub(str, format("([^%s]+)", delimiter), function(c) fields[getn(fields) + 1] = c end)

	return unpack(fields)
end
strsplit = string.split

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
function string.trim(str, chars)
	if type(str) ~= "string" and type(str) ~= "number" then
		error(format("bad argument #1 to 'trim' (string expected, got %s)", str and type(str) or "no value"), 2)
	elseif chars and (type(chars) ~= "string" and type(chars) ~= "number") then
		error(format("bad argument #2 to 'trim' (string expected, got %s)", chars and type(chars) or "no value"), 2)
	end

	str = type(str) == "number" and tostring(str) or str

	if chars then
		chars = type(chars) == "number" and tostring(chars) or chars

		local tokens = {}

		for token in gfind(chars, "[%z\1-\255]") do
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

		local patternStart = loadstring("return \"^["..pattern.."](.-)$\"")()
		local patternEnd = loadstring("return \"^(.-)["..pattern.."]$\"")()

		local trimed, x, y = 1
		while trimed >= 1 do
			str, x = gsub(str, patternStart, "%1")
			str, y = gsub(str, patternEnd, "%1")
			trimed = x + y
		end

		return str
	else
		-- remove leading/trailing [space][tab][return][newline]
		return gsub(str, "^%s*(.-)%s*$", "%1")
	end
end
strtrim = string.trim

function table.wipe(t)
	if type(t) ~= "table" then
		error(format("bad argument #1 to 'wipe' (table expected, got %s)", t and type(t) or "no value"), 2)
	end

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
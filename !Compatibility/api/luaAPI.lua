--Cache global variables
local error = error
local geterrorhandler = geterrorhandler
local loadstring = loadstring
local next = next
local pairs = pairs
local pcall = pcall
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local abs, ceil, exp, floor = math.abs, math.ceil, math.exp, math.floor
local find, format, gfind, gsub, len, sub = string.find, string.format, string.gfind, string.gsub, string.len, string.sub
local concat, getn, setn, tremove = table.concat, table.getn, table.setn, table.remove

math.fmod = math.mod
math.huge = 1/0
string.gmatch = string.gfind
gmatch = string.gfind

local MAXN = 2147483647
local function toInt(x)
	if x == floor(x) then return x end

	if x > 0 then
		x = floor(x + 0.5)
	else
		x = ceil(x - 0.5)
	end

	return x
end
function select(n, ...)
	if not (type(n) == "number" or (type(n) == "string" and n == "#")) then
		error(format("bad argument #1 to 'select' (number expected, got %s)", n and type(n) or "no value"), 2)
	end

	if n == "#" then
		return arg.n
	elseif n == 0 or n > MAXN then
		error("bad argument #1 to 'select' (index out of range)", 2)
	elseif n == 1 then
		return unpack(arg)
	end

	if n < 0 then
		n = arg.n + n + 1
	end
	n = toInt(n)

	for i = 1, n - 1 do
		tremove(arg, 1)
	end

	return unpack(arg)
end

local huge = math.huge
function math.modf(i)
	i = type(i) ~= "number" and tonumber(i) or i

	if type(i) ~= "number" then
		error(format("bad argument #1 to 'modf' (number expected, got %s)", i and type(i) or "no value"), 2)
	end

	if i == 0 then
		return i, i
	elseif abs(i) == huge then
		return i, i > 0 and 0 or -0
	end

	local int = i > 0 and floor(i) or ceil(i)

	return int, i - int
end

function math.cosh(i)
	i = type(i) ~= "number" and tonumber(i) or i

	if type(i) ~= "number" then
		error(format("bad argument #1 to 'cosh' (number expected, got %s)", i and type(i) or "no value"), 2)
	end

	if i < 0 then
		i = -i
	end

	if i > 21 then
		return exp(i) / 2
	end

	return (exp(i) + exp(-i)) / 2
end

local sinhC = {
	["P0"] = -0.6307673640497716991184787251e+6,
	["P1"] = -0.8991272022039509355398013511e+5,
	["P2"] = -0.2894211355989563807284660366e+4,
	["P3"] = -0.2630563213397497062819489e+2,
	["Q0"] = -0.6307673640497716991212077277e+6,
	["Q1"] = 0.1521517378790019070696485176e+5,
	["Q2"] = -0.173678953558233699533450911e+3
}
function math.sinh(i)
	i = type(i) ~= "number" and tonumber(i) or i

	if type(i) ~= "number" then
		error(format("bad argument #1 to 'sinh' (number expected, got %s)", i and type(i) or "no value"), 2)
	end

	local neg, x

	if i < 0 then
		i = -i
		neg = true
	end

	if i > 21 then
		x = exp(i) / 2
	elseif i > 0.5 then
		x = (exp(i) - exp(-i)) / 2
	else
		local sq = i * i
		x = (((sinhC["P3"] * sq + sinhC["P2"]) * sq + sinhC["P1"]) * sq + sinhC["P0"]) * i
		x = x / (((sq + sinhC["Q2"]) * sq + sinhC["Q1"]) * sq + sinhC["Q0"])
	end

	if neg then
		x = -x
	end

	return x
end

local MAXLOG2 = 8.8029691931113054295988e+01 * 0.5
local tanhP = {
	-9.64399179425052238628E-1,
	-9.92877231001918586564E1,
	-1.61468768441708447952E3,
}
local tanhQ = {
	1.12811678491632931402E2,
	2.23548839060100448583E3,
	4.84406305325125486048E3,
}
function math.tanh(i)
	i = type(i) ~= "number" and tonumber(i) or i

	if type(i) ~= "number" then
		error(format("bad argument #1 to 'tanh' (number expected, got %s)", i and type(i) or "no value"), 2)
	end

	if i == 0 then
		return i
	end

	local x = abs(i)

	if x > MAXLOG2 then
		return i < 0 and -1 or 1
	elseif x >= 0.625 then
		local s = exp(2 * x)
		x = 1 - 2 / (s + 1)

		if i < 0 then
			x = -x
		end
	else
		local sq = i * i
		x = i + i * sq * ((tanhP[1] * sq + tanhP[2]) * sq + tanhP[3]) / (((sq + tanhQ[1]) * sq + tanhQ[2]) * sq + tanhQ[3])
	end

	return x
end

function string.join(delimiter, ...)
	if type(delimiter) ~= "string" and type(delimiter) ~= "number" then
		error(format("bad argument #1 to 'join' (string expected, got %s)", delimiter and type(delimiter) or "no value"), 2)
	end

	if arg.n == 0 then
		return ""
	end

	return concat(arg, delimiter)
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

	local i1, i2, match, match2 = find(str, pattern, index)

	if not match and i2 and i2 >= i1 then
		return sub(str, i1, i2)
	elseif match2 then
		local matches = {find(str, pattern, index)}
		tremove(matches, 2)
		tremove(matches, 1)
		return unpack(matches)
	end

	return match
end
strmatch = string.match

function string.reverse(str)
	if type(str) ~= "string" and type(str) ~= "number" then
		error(format("bad argument #1 to 'reverse' (string expected, got %s)", str and type(str) or "no value"), 2)
	end

	local size = len(str)
	if size > 1 then
		local reversed = ""
		for i = size, 1, -1 do
			reversed = reversed .. sub(str, i, i)
		end

		return reversed
	end

	return str
end
strrev = string.reverse

function string.split(delimiter, str)
	if type(delimiter) ~= "string" and type(delimiter) ~= "number" then
		error(format("bad argument #1 to 'split' (string expected, got %s)", delimiter and type(delimiter) or "no value"), 2)
	elseif type(str) ~= "string" and type(str) ~= "number" then
		error(format("bad argument #2 to 'split' (string expected, got %s)", str and type(str) or "no value"), 2)
	end

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

	if chars then
		local tokens = {}
		local size = 0

		for token in gfind(chars, "[%z\1-\255]") do
			size = size + 1
			tokens[size] = token
		end

		local pattern = ""

		for i = 1, size do
			pattern = pattern..(escapeSequences[tokens[i]] or tokens[i]).."+"

			if i < size then
				pattern = pattern.."|"
			end
		end

		local patternStart = loadstring("return \"^["..pattern.."](.-)$\"")()
		local patternEnd = loadstring("return \"^(.-)["..pattern.."]$\"")()

		local trimed, x, y = 1, 1, 1
		while trimed > 0 do
			if x > 0 then
				str, x = gsub(str, patternStart, "%1")
			end
			if y > 0 then
				str, y = gsub(str, patternEnd, "%1")
			end

			trimed = x + y
		end

		return str
	elseif type(str) == "string" then
		-- remove leading/trailing [space][tab][return][newline]
		return gsub(str, "^%s*(.-)%s*$", "%1")
	else
		return tostring(str)
	end
end
strtrim = string.trim

function strconcat(...)
	if arg.n == 0 then
		return ""
	elseif arg.n == 1 then
		return tostring(arg[1])
	else
		for i = 1, arg.n do
			if type(arg[i]) ~= "string" then
				error(format("attempt to concatenate a %s value", type(arg[i])), 2)
			end
		end
	end

	return concat(arg)
end

function table.maxn(t)
	if type(t) ~= "table" then
		error(format("bad argument #1 to 'maxn' (table expected, got %s)", t and type(t) or "no value"), 2)
	end

	local maxn = 0
	local i = next(t)

	while i do
		if type(i) == "number" and i > maxn then
			maxn = i
		end
		i = next(t, i)
	end

	return maxn
end

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
	local n = arg.n
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

local strjoin = strjoin
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
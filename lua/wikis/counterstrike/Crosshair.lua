local Crosshair = {}

local bit32 = require( 'bit32' )
local Base57 = require('Module:Base57')
local crosshairBg = require('Module:CrosshairCommons').crosshairColors


local band, blshift, brshift = bit32.band, bit32.lshift, bit32.rshift

-- Converts a byte to his signed value
local function signed(dec)
	if dec > 127 then
		return -1 * (band(bit32.bnot(dec),0xff)) -1
	end
	return dec
end

-- reverts signed function
local function unsigned(dec)
	if dec < 0 then
		return band(bit32.bnot(dec* -1 -1),0xff)
	end
	return dec
end

-- 8 bit check sum its the sum of all bytes excluding the MSB and of the sum return only the LSB matter
local function eightBitChecksum(bytes)
	local sum = 0
	for i = 2, #bytes do
		sum = sum + bytes[i]
	end
	return bit32.extract(sum,0,8)
end

local function padStartTable(tbl, targetLength, value)
	local tableSize = 0
	for _ in pairs(tbl) do
		tableSize = tableSize + 1
	end
	while tableSize < targetLength do
		table.insert(tbl, 1, value)
		tableSize = tableSize + 1
	end
end

local function padEndString(string,targetLength,padChar)
	while #string < targetLength do
		string = string .. padChar
	end
	return string
end

local function crosshairToBytes(crosshair)
	local bytes = {}
	for i = 1, 18 do
		bytes[i] = 0
	end

	-- this byte seem to always be 1
	bytes[2] = 1

	bytes[3] = unsigned(crosshair["cl_crosshairgap"] * 10)
	bytes[4] = band(crosshair["cl_crosshair_outlinethickness"]* 2.0, 7)
	bytes[5] = band(crosshair["cl_crosshaircolor_r"],0xff)
	bytes[6] = band(crosshair["cl_crosshaircolor_g"],0xff)
	bytes[7] = band(crosshair["cl_crosshaircolor_b"],0xff)
	bytes[8] = band(crosshair["cl_crosshairalpha"],0xff)
	bytes[9] = band(crosshair["cl_crosshair_dynamic_splitdist"],0xff)
	bytes[10] = unsigned(crosshair["cl_fixedcrosshairgap"] * 10)

	bytes[11] = band(crosshair["cl_crosshair_dynamic_splitalpha_innermod"] * 10 , 0x0F)
	bytes[11] = blshift(bytes[11], 1) + band(crosshair["cl_crosshair_drawoutline"], 0x1)
	bytes[11] = blshift(bytes[11], 3) + band(crosshair["cl_crosshaircolor"], 7)

	bytes[12] = band(crosshair["cl_crosshair_dynamic_maxdist_splitratio"] * 10 ,0x0F)
	bytes[12] = blshift(bytes[12], 4) + band(crosshair["cl_crosshair_dynamic_splitalpha_outermod"] * 10,0x0F)

	bytes[13] = band(crosshair["cl_crosshairthickness"]* 10, 0x3F)

	bytes[14] = crosshair["cl_crosshair_t"]
	bytes[14] = blshift(bytes[14], 1) + band(crosshair["cl_crosshairusealpha"], 0x1)
	bytes[14] = blshift(bytes[14], 1) + band(crosshair["cl_crosshairgap_useweaponvalue"], 0x1)
	bytes[14] = blshift(bytes[14], 1) + band(crosshair["cl_crosshairdot"], 0x1)
	bytes[14] = blshift(bytes[14], 3) + band(crosshair["cl_crosshairstyle"], 0xE)
	bytes[14] = blshift(bytes[14], 1)

	local size = crosshair["cl_crosshairsize"] * 10
	bytes[15] = band(size,0xFF) -- last bytes
	bytes[16] = band(brshift(size,8),0x1f)

	bytes[1] = eightBitChecksum(bytes)

	return bytes
end

-- Verifies the inputed shareCode
local function validateShareCode(shareCode)
	if shareCode == nil then
		error("Code can't be nil")
	end
	if not type(shareCode) == string then
		error("Invalid type")
	end
	if #shareCode ~= 34 then
		error("Invalid length, should have 34 character")
	end
	local sCSGO, eCSGO = string.find(shareCode,"CSGO")
	if sCSGO ~= 1 or eCSGO ~=4 then
		error("Codes start with 'CSGO'")
	end

	return true
end

local function setValueDefault(value,default,min,max)
	local num = tonumber(value)
	if num == nil then
		return default
	end
	if num < min then return min end
	if num > max then return max end

	return num
end

local function setValue(value,min,max)
	local num = tonumber(value)
	if num == nil then
		return num
	end
	if num < min then return min end
	if num > max then return max end

	return num
end

function Crosshair.fromArgs(args)
	return {
		["cl_crosshair_dynamic_maxdist_splitratio"] = setValueDefault(args.dynamic_maxdist_splitratio,0.3,0,1), --f
		["cl_crosshair_dynamic_splitalpha_innermod"] = setValueDefault(args.dynamic_splitalpha_innermod,1,0,1), --f
		["cl_crosshair_dynamic_splitalpha_outermod"] = setValueDefault(args.dynamic_splitalpha_outermod,0.5,0.3,1), --f
		["cl_crosshair_dynamic_splitdist"] = setValueDefault(args.dynamic_splitdist,7,0,127),
		["cl_crosshair_friendly_warning"] = tonumber(args.friendly_warning) or 0,
		["cl_crosshair_outlinethickness"] = setValueDefault(args.outlinethickness,1,0,3),
		["cl_crosshair_drawoutline"] =  args.outline~=nil and setValue(args.outline,0,1) or ((tonumber(args.outlinethickness) ~= nil and tonumber(args.outlinethickness)>0) and 1 or 0),
		["cl_crosshair_sniper_show_normal_inaccuracy"] = tonumber(args.sniper_show_normal_inaccuracy) or 1,
		["cl_crosshair_sniper_width"] = tonumber(args.sniper) or  1,
		["cl_crosshair_t"] = setValueDefault(args.t,0,0,1),
		["cl_crosshairalpha"] = setValueDefault(args.alpha,255,0,255),
		["cl_crosshaircolor"] = setValueDefault(args.color,1,0,5),
		["cl_crosshaircolor_b"] = (args.color ~= nil and args.color == "5" and setValue(args.b,0,255) or setValueDefault(args.b,50,0,255)),
		["cl_crosshaircolor_g"] = (args.color ~= nil and args.color == "5" and setValue(args.g,0,255) or setValueDefault(args.g,250,0,255)),
		["cl_crosshaircolor_r"] = (args.color ~= nil and args.color == "5" and setValue(args.r,0,255) or setValueDefault(args.r,50,0,255)),
		["cl_crosshairdot"] = setValue(args.dot,0,1),
		["cl_crosshairgap"] = setValue(args.gap,-12.8,12.7),
		["cl_crosshairgap_useweaponvalue"] = setValueDefault(args.gap_useweaponvalue,0,0,1),
		["cl_crosshairsize"] = setValue(args.size,0,819.1),
		["cl_crosshairstyle"] =  setValue(args.style,0,7),
		["cl_crosshairthickness"] =  setValue(args.thickness,0,6.3),
		["cl_crosshairusealpha"] = ((tonumber(args.alpha) ~= nil and tonumber(args.alpha)>0) and 1 or 0),
		["cl_fixedcrosshairgap"] = setValueDefault(args.fixedcrosshairgap,3,-12.8,12.7),
	}
end

function Crosshair.decode(shareCode)
	if not validateShareCode(shareCode) then
		error("Invalid share code inserted")
	end
	shareCode = shareCode:gsub("CSGO", ""):gsub("-","")
	if #shareCode ~= 25 then
		error("Invalid share code length")
	end

	local bytes = Base57.decode(shareCode)

	if bytes == nil then
		error("Invalid base57 string")
		return
	end
	-- add a byte 0 to make bytes unsigned
	padStartTable(bytes, 18, 0)
	-- now bytes contains the decoded number (big endian)
	-- validate checksum
	if eightBitChecksum(bytes) ~= bytes[1] then
		error("Invalid share code")
	end

	local crosshair = {
		["cl_crosshairgap"] = signed(bytes[3]) / 10.0,

		["cl_crosshair_outlinethickness"] = band(bytes[4], 7) / 2.0,

		["cl_crosshaircolor_r"] = bytes[5],
		["cl_crosshaircolor_g"] = bytes[6],
		["cl_crosshaircolor_b"] = bytes[7],
		["cl_crosshairalpha"] = bytes[8],
		["cl_crosshair_dynamic_splitdist"] = bytes[9],

		["cl_fixedcrosshairgap"] = signed(bytes[10]) / 10.0,

		["cl_crosshaircolor"] = band(bytes[11], 7),
		["cl_crosshair_drawoutline"] = bit32.btest(bytes[11], 8) and  1 or 0,
		["cl_crosshair_dynamic_splitalpha_innermod"] = (brshift(band(bytes[11], 0xF0), 4)) / 10.0,

		["cl_crosshair_dynamic_splitalpha_outermod"] = band(bytes[12],0xF) / 10.0,
		["cl_crosshair_dynamic_maxdist_splitratio"] = (brshift(band(bytes[12], 0xF0),4)) / 10.0,

		["cl_crosshairthickness"] = band(bytes[13], 0x3F) / 10.0,

		["cl_crosshairstyle"] = brshift(band(bytes[14], 0xE),1),
		["cl_crosshairdot"] = bit32.btest(bytes[14], 0x10) and 1 or 0,
		["cl_crosshairgap_useweaponvalue"] = bit32.btest(bytes[14], 0x20) and 1 or 0,
		["cl_crosshairusealpha"] = bit32.btest(bytes[14], 0x40) and 1 or 0,
		["cl_crosshair_t"] = bit32.btest(bytes[14], 0x80)  and 1 or 0,

		["cl_crosshairsize"] = (bit32.lshift(band(bytes[16],0x1f), 8) + bytes[15]) / 10.0,
		-- default values (don't change with share code)
		["cl_crosshair_friendly_warning"] = 0,
		["cl_crosshair_sniper_show_normal_inaccuracy"] = 1,
		["cl_crosshair_sniper_width"] = 1
	}

	return crosshair
end

function Crosshair.encode(crosshair)
	local bytes = crosshairToBytes(crosshair)
	local shareCode = Base57.encode(bytes)

	if #shareCode ~= 25 then
		shareCode = padEndString(shareCode,25,'A')
	end

	return "CSGO-"..shareCode:sub(1,5).."-"..shareCode:sub(6,10).."-"..shareCode:sub(11,15).."-"..shareCode:sub(16,20).."-"..shareCode:sub(21,25)
end

local function roundBigFloats(number)
	local mod_str = string.format("%.3f",math.fmod(number,1))
		if mod_str >= "0.500" then
			if mod_str == "0.500" then
					return math.floor(number-0.1)
			end
			return math.ceil(number)
		end
		return math.floor(number)
end

local function simpleRound(number)
	return number>=0 and math.floor(number+0.5) or math.ceil(number-0.5)
end

local function createPip(wrapper, width, height, marginLeft, marginTop, zIndex, backgroundColor)
	local element = wrapper:tag('div')
				:css({
					["position"] = "absolute",
					["width"] = width .."px",
					["height"] = height .."px",
					["margin-left"] = simpleRound(marginLeft) .."px",
					["margin-top"] =  simpleRound(marginTop).."px",
					["z-index"] =  zIndex,
					["background-color"] = backgroundColor,
			})
	return element
end

-- Crosshair is drawn inside a div 82px x 82px
function Crosshair.makePreview(crosshair, resHeight)
	if crosshair == nil or type(crosshair) ~= 'table' then
		return ""
	end

	if resHeight == nil or resHeight == "" then
		resHeight = 1080
	end

	local function YRES(y)
		return y * (resHeight/480.0)
	end

	if crosshair["cl_crosshaircolor"] > 5 then
		crosshair["cl_crosshaircolor"] = 1
	end

	local crosshairStyle = crosshair["cl_crosshairstyle"]

	if crosshairStyle < 2 then
		return ""
	end

	local crosshairSize = crosshair["cl_crosshairsize"]
	local crosshairThickness = crosshair["cl_crosshairthickness"]
	local crosshairGap = crosshair["cl_crosshairgap"]
	local crosshairAlpha = crosshair["cl_crosshairalpha"]

	local crosshairT = crosshair["cl_crosshair_t"]
	local crosshairDot = crosshair["cl_crosshairdot"]
	local crosshairOutlineThickness = crosshair["cl_crosshair_outlinethickness"]

	if crosshair["cl_crosshaircolor"] == 5 then
		crosshairBg[5] = "rgb("..crosshair["cl_crosshaircolor_r"]..","..crosshair["cl_crosshaircolor_g"]..",".. crosshair["cl_crosshaircolor_b"]..")"
	end

	local bgColor = crosshairBg[crosshair["cl_crosshaircolor"]]

	local pipDistance = roundBigFloats(resHeight / 1200.0 + crosshairGap)
	local pipSize = roundBigFloats(YRES(crosshairSize))
	local pipThickness = math.max(1,roundBigFloats(YRES(crosshairThickness)))

	local wrapper = mw.html.create('div')

	if crosshairStyle >= 2 then
		pipDistance = 4 + simpleRound(crosshairGap)
		pipDistance = 2 * pipDistance + pipThickness

		local marginSides = (82 - (pipSize * 2 + pipDistance))/2
		local offset = marginSides + pipSize + ( pipDistance - pipThickness)/2

		local pipTop = createPip(wrapper, pipThickness, pipSize, 82/2 - pipThickness/2, marginSides, 1, bgColor)
		local pipDown = createPip(wrapper, pipThickness, pipSize, 82/2 - pipThickness/2, marginSides + pipSize + pipDistance, 1, bgColor)

		local pipLeft = createPip(wrapper, pipSize, pipThickness, marginSides, offset, 1, bgColor)
		local pipRight = createPip(wrapper, pipSize, pipThickness, marginSides + pipSize + pipDistance, offset, 1, bgColor)

		local dot = createPip(wrapper, pipThickness, pipThickness, offset, offset, 1, bgColor)

		if crosshair["cl_crosshair_drawoutline"] == 1 and crosshairOutlineThickness~=0 then
			local propOutline = crosshairOutlineThickness .. "px solid black"
			local isFloat = math.floor(crosshairOutlineThickness) ~= crosshairOutlineThickness
			if isFloat then
				local down_round = math.floor(crosshairOutlineThickness)
				local up_round = math.ceil(crosshairOutlineThickness)
				local round_sum = down_round + up_round
				--top/down shadow
				if crosshairT == 0 then
					createPip(wrapper, pipThickness + round_sum, pipSize + round_sum, 82/2 - pipThickness/2 - down_round, marginSides - down_round, 0, "black")
				end
				createPip(wrapper, pipThickness + round_sum, pipSize + round_sum, 82/2 - pipThickness/2 - down_round, marginSides + pipSize + pipDistance - down_round, 0, "black")

				--left/right shadow
				createPip(wrapper, pipSize + round_sum, pipThickness + round_sum, marginSides - down_round, offset - down_round, 0, "black")
				createPip(wrapper, pipSize + round_sum, pipThickness + round_sum, marginSides + pipSize + pipDistance - down_round, offset - down_round, 0, "black")

				--dot shadow
				if crosshairDot == 1 then
					createPip(wrapper, pipThickness + round_sum, pipThickness + round_sum, offset - down_round, offset - down_round, 0, bgColor)
				end
			end

			if crosshairOutlineThickness >= 1 then
				pipTop:css("outline", propOutline)
				pipDown:css("outline", propOutline)
				pipLeft:css("outline", propOutline)
				pipRight:css("outline", propOutline)
				dot:css("outline", propOutline)
			end

			if pipSize <= 0 then
				pipTop:css("display", "none")
				pipDown:css("display", "none")
				pipLeft:css("display", "none")
				pipRight:css("display", "none")
			end
		end

		if crosshairT == 1 then
			pipTop:css("display", "none")
		end

		if crosshairDot == 0 then
			dot:css("display", "none")
		end
	end

	if crosshair["cl_crosshairusealpha"] == 1 then
		wrapper:css("opacity",crosshairAlpha/250)
	end

	return tostring(wrapper)
end

return Crosshair

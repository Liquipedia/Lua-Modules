---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

---@class CounterstrikeNormalMapParser: MapParserInterface
local CustomMatchGroupInputMatchNormal = {}

---@param match table
---@param map table
---@param opponents MGIParsedOpponent[]
---@return table
function CustomMatchGroupInputMatchNormal.getExtraData(match, map, opponents)
	local extradata = CustomMatchGroupInputMatchNormal._getHalfScores(map)
	-- Id of the on-wiki page holding this map's player stats JSON 
	extradata.nuselo = map.nuselo
	return extradata
end

---@param map table
---@return table
function CustomMatchGroupInputMatchNormal._getHalfScores(map)
	local t1sides = {}
	local t2sides = {}
	local t1halfs = {}
	local t2halfs = {}

	local prefix = ''
	local overtimes = 0

	local function getOppositeSide(side)
		return side == 'ct' and 't' or 'ct'
	end

	while true do
		local t1Side = map[prefix .. 't1firstside']
		if Logic.isEmpty(t1Side) or (t1Side ~= 'ct' and t1Side ~= 't') then
			break
		end
		local t2Side = getOppositeSide(t1Side)

		-- Iterate over two Halfs (In regular time a half is 12 rounds, after that sides switch)
		for _ = 1, 2, 1 do
			if(map[prefix .. 't1' .. t1Side] and map[prefix .. 't2' .. t2Side]) then
				table.insert(t1sides, t1Side)
				table.insert(t2sides, t2Side)
				table.insert(t1halfs, tonumber(map[prefix .. 't1' .. t1Side]) or 0)
				table.insert(t2halfs, tonumber(map[prefix .. 't2' .. t2Side]) or 0)
				-- second half (sides switch)
				t1Side, t2Side = t2Side, t1Side
			end
		end

		overtimes = overtimes + 1
		prefix = 'o' .. overtimes
	end

	return {
		t1sides = t1sides,
		t2sides = t2sides,
		t1halfs = t1halfs,
		t2halfs = t2halfs,
	}
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInputMatchNormal.calculateMapScore(map)
	local halfs = CustomMatchGroupInputMatchNormal._getHalfScores(map)
	return function(opponentIndex)
		return Array.reduce(halfs['t' .. opponentIndex .. 'halfs'], Operator.add)
	end
end

return CustomMatchGroupInputMatchNormal

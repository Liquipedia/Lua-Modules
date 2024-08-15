---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match/Subobjects
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local FeatureFlag = require('Module:FeatureFlag')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local ENTRY_POINT_NAMES = {'getMap'}

local MatchSubobjects = {}

---@param frame Frame
---@return string
function MatchSubobjects.getMap(frame)
	local args = Arguments.getArgs(frame)
	return Json.stringify(MatchSubobjects.luaGetMap(args))
end

---@param args table
---@return table?
function MatchSubobjects.luaGetMap(args)
	-- dont save map if 'map' is not filled in
	if Logic.isEmpty(args.map) then
		return nil
	else
		args = WikiSpecific.processMap(args)

		args.participants = args.participants or {}
		for key, item in pairs(args.participants) do
			if not key:match('%d_%d') then
				error('Key \'' .. key .. '\' in match2game.participants has invalid format: \'<number>_<number>\' expected')
			elseif type(item) ~= 'table' then
				error('Item \'' .. tostring(item) .. '\' in match2game.participants has invalid format: table expected')
			end
		end

		return args
	end
end

if FeatureFlag.get('perf') then
	local Match = Lua.import('Module:Match')
	MatchSubobjects.perfConfig = Match.perfConfig
end

Lua.autoInvokeEntryPoints(MatchSubobjects, 'Module:Match/Subobjects', ENTRY_POINT_NAMES)

return MatchSubobjects

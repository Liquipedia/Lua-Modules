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
local wikiSpec = require('Module:Brkts/WikiSpecific')

local MatchSubobjects = {}

function MatchSubobjects.getMap(frame)
	local args = Arguments.getArgs(frame)
	return Json.stringify(MatchSubobjects.luaGetMap(frame, args))
end

function MatchSubobjects.luaGetMap(frame, args)
	-- dont save map if 'map' is not filled in
	if Logic.isEmpty(args.map) then
		return nil
	else
		args = wikiSpec.processMap(frame, args)

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

function MatchSubobjects.getRound(frame)
	local args = Arguments.getArgs(frame)
	return Json.stringify(MatchSubobjects.luaGetRound(frame, args))
end

function MatchSubobjects.luaGetRound(frame, args)
	return args
end

function MatchSubobjects.getPlayer(frame)
	local args = Arguments.getArgs(frame)
	return Json.stringify(MatchSubobjects.luaGetPlayer(frame, args))
end

function MatchSubobjects.luaGetPlayer(frame, args)
	return wikiSpec.processPlayer(frame, args)
end

local _ENTRY_POINT_NAMES = {'getMap', 'getPlayer', 'getRound'}

if FeatureFlag.get('perf') then
	local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})
	MatchSubobjects.perfConfig = Match.perfConfig
	require('Module:Performance/Util').setupEntryPoints(MatchSubobjects, _ENTRY_POINT_NAMES)
end

Lua.autoInvokeEntryPoints(MatchSubobjects, 'Module:Match/Subobjects', _ENTRY_POINT_NAMES)

return MatchSubobjects

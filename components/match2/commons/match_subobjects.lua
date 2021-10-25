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
local Table = require('Module:Table')
local wikiSpec = require('Module:Brkts/WikiSpecific')

local ALLOWED_OPPONENT_TYPES = { 'literal', 'team', 'solo', 'duo', 'trio', 'quad' }

local MatchSubobjects = {}

function MatchSubobjects.getOpponent(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchSubobjects_ = Lua.import('Module:Match/Subobjects', {requireDevIfEnabled = true})
		return MatchSubobjects_.withPerformanceSetup(function()
			return Json.stringify(MatchSubobjects_.luaGetOpponent(frame, args))
		end)
	end)
end

function MatchSubobjects.luaGetOpponent(frame, args)
	if not Table.includes(ALLOWED_OPPONENT_TYPES, args.type) then
		error('Unknown opponent type ' .. args.type)
	end

	args = wikiSpec.processOpponent(frame, args)
	args.match2players = args.players or Json.parseIfString(args.match2players)
	return args
end

function MatchSubobjects.getMap(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchSubobjects_ = Lua.import('Module:Match/Subobjects', {requireDevIfEnabled = true})
		return MatchSubobjects_.withPerformanceSetup(function()
			return Json.stringify(MatchSubobjects_.luaGetMap(frame, args))
		end)
	end)
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
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchSubobjects_ = Lua.import('Module:Match/Subobjects', {requireDevIfEnabled = true})
		return MatchSubobjects_.withPerformanceSetup(function()
			return Json.stringify(MatchSubobjects_.luaGetPlayer(frame, args))
		end)
	end)
end

function MatchSubobjects.luaGetPlayer(frame, args)
	return wikiSpec.processPlayer(frame, args)
end

function MatchSubobjects.withPerformanceSetup(f)
	if FeatureFlag.get('perf') then
		local config = Lua.loadDataIfExists('Module:MatchGroup/Config')
		local perfConfig = Table.getByPathOrNil(config, {'subobjectPerf'}) or {}
		return require('Module:Performance/Util').withSetup(perfConfig, f)
	else
		return f()
	end
end

return MatchSubobjects

---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:LegacyBracketMatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
	This module is used in the process of converting Legacy match1 into match2.
	It converts a few fields to new format, and jsonify the args.
	It is invoked by Template:BracketMatchSummary.
]]

local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Class = require('Module:Class')

local LegacyBracketMatchSummary = {}

function LegacyBracketMatchSummary.convert(args)
	if not args then
		return
	end
	local index = 1
	while not String.isEmpty(args['map' .. index]) or not String.isEmpty(args['map' .. index .. 'win']) do
		local prefix = 'map' .. index
		local score1
		local score2
		if not String.isEmpty(args[prefix..'score']) then
			score1 = mw.text.split(args[prefix..'score'], '-')[1]
			score2 = mw.text.split(args[prefix..'score'], '-')[2]
		end
		if not score1 and not score2 and args[prefix ..'win'] ~= 'skip' then
			score1 = tonumber(args[prefix ..'win']) == 1 and 'W' or 'L'
			score2 = tonumber(args[prefix ..'win']) == 2 and 'W' or 'L'
		end

		args['map' .. index .. 'score1'] = mw.text.trim(score1 or '')
		args['map' .. index .. 'score2'] = mw.text.trim(score2 or '')
		args['map' .. index .. 'score'] = nil
		args['map' .. index .. 'finished'] = (args[prefix ..'win'] == 'skip' and 'skip') or
											(not String.isEmpty(args[prefix ..'win']) and 'true') or 'false'
		args['map' .. index .. 'win'] = nil
		index = index + 1
	end

	-- map veto (legacy only have 7 map pool support)
	local veto = Json.parseIfString(args.mapbans)
	if veto and veto.r1 and veto.r2 and veto.r3 and veto.r4 then
		args['mapveto'] = {
			firstpick = veto.firstban,
			types = veto.r1..','..veto.r2..','..veto.r3..','..veto.r4,
			t1map1 = veto.t1map1,
			t1map2 = veto.t1map2,
			t1map3 = veto.t1map3,
			t2map1 = veto.t2map1,
			t2map2 = veto.t2map2,
			t2map3 = veto.t2map3,
			decider = veto.map4,
		}
	end
	args.mapbans = nil

	return Json.stringify(args)
end

return Class.export(LegacyBracketMatchSummary)

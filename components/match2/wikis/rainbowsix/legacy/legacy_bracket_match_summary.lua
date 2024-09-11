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

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DRAW = 'draw'
local SKIP = 'skip'

local LegacyBracketMatchSummary = {}

function LegacyBracketMatchSummary.convert(args)
	if not args then
		return
	end
	local index = 1
	while not String.isEmpty(args['map' .. index]) or not Logic.isEmpty(args['map' .. index .. 'win']) do
		local prefix = 'map' .. index
		local winner = Table.extract(args, prefix .. 'win')
		local score = Table.extract(args, prefix .. 'score')
		if Logic.isNotEmpty(score) then
			local splitedScore = Array.parseCommaSeparatedString(score, '-')
			args[prefix .. 'score1'] = splitedScore[1]
			args[prefix .. 'score2'] = splitedScore[2]
		end

		args[prefix .. 'finished'] = (winner == SKIP and SKIP) or
											(not Logic.isEmpty(winner) and 'true') or 'false'
		if Logic.isNumeric(winner) or winner == DRAW then
			args[prefix .. 'win'] = winner == DRAW and 0 or winner
		end

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

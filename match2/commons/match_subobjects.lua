local p = {}

local json = require("Module:Json")
local Table = require("Module:Table")
local Logic = require("Module:Logic")
local String = require("Module:StringUtils")
local getArgs = require("Module:Arguments").getArgs
local wikiSpec = require("Module:Brkts/WikiSpecific")

local ALLOWED_OPPONENT_TYPES = { "literal", "team", "solo", "duo", "trio", "quad" }

function p.getOpponent(frame)
	local args = getArgs(frame)
	return p.luaGetOpponent(frame, args)
end

function p.luaGetOpponent(frame, args)
	if not Table.includes(ALLOWED_OPPONENT_TYPES, args.type) then
		error("Unknown opponent type " .. args.type)
	end

	args = wikiSpec.processOpponent(frame, args)
	return json.stringify({
		["type"] = args.type,
		template = args.template,
		name = args.name,
		score = args.score,
		extradata = args.extradata,
		match2players = args.players or args.match2players,
		icon = args.icon
		-- other variables such as placement and status are set from Module:MatchGroup
	})
end

function p.getMap(frame)
	local args = getArgs(frame)
	return p.luaGetMap(frame, args)
end

function p.luaGetMap(frame, args)
	-- dont save map if 'map' is not filled in
	if Logic.isEmpty(args.map) then
		return nil
	else
		args = wikiSpec.processMap(frame, args)

		local participants = args.participants or {}
		if type(participants) == "string" then
			participants = json.parse(participants)
		end
		for key, item in pairs(participants) do
			if not key:match("%d_%d") then
				error("Key '" .. key .. "' in match2game.participants has invalid format: '<number>_<number>' expected")
			elseif type(item) == "string" and String.startsWith(item, "{") then
				participants[key] = json.parse(item)
			elseif type(item) ~= "table" then
				error("Item '" .. tostring(item) .. "' in match2game.participants has invalid format: table expected")
			end
		end
		args.participants = participants

		return json.stringify({
			map = args.map,
			scores = args.scores,
			winner = args.winner,
			mode = args.mode,
			["type"] = args.type,
			game = args.game,
			date = args.date,
			vod = args.vod,
			extradata = args.extradata,
			length = args.length,
			walkover = args.walkover,
			resulttype = args.resulttype,
			participants = args.participants,
			rounds = args.rounds,
			subgroup = args.subgroup
		})
	end
end

function p.getRound(frame)
	local args = getArgs(frame)
	return p.luaGetRound(frame, args)
end

function p.luaGetRound(frame, args)
	return json.stringify(args)
end

function p.getPlayer(frame)
	local args = getArgs(frame)
	return p.luaGetPlayer(frame, args)
end

function p.luaGetPlayer(frame, args)
	args = wikiSpec.processPlayer(frame, args)
	return json.stringify({
		name = args.name,
		displayname = args.displayname,
		flag = args.flag,
		extradata = args.extradata
	})
end

return p

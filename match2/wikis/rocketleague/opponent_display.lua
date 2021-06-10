local p = {}

local getArgs = require("Module:Arguments").getArgs
local utils = require("Module:LuaUtils")
local htmlCreate = mw.html.create

function p.get(frame)
	local args = getArgs(frame)
	return p.luaGet(frame, args)
end

function p.luaGet(frame, args)
	local displayType = args.displaytype
	local opponentType = args.type
	local wrapper = htmlCreate("div")
		:addClass("brkts-opponent-wrapper")
	if displayType == "bracket" or displayType == "bracket-qualified" then
		if opponentType == "team" then
			local team = p._getTeam(frame, args.template)
			local container = htmlCreate("div")
				:addClass("brkts-opponent-template-container")
				:node(htmlCreate("div")
					:addClass("hidden-xs")
					:wikitext(team.bracket))
				:node(htmlCreate("div")
					:addClass("visible-xs")
					:wikitext(team.short))
			wrapper:node(container)
		elseif opponentType == "solo" then
			local container = htmlCreate("div")
				:addClass("brkts-opponent-template-container brkts-player-container")
				:wikitext(utils.frame.protectedExpansion(frame, "Player", {
					args.match2player1_name , flag = args.match2player1_flag }))
			wrapper:node(container)
		elseif opponentType == "literal" then
			local container = htmlCreate("div")
				:addClass("brkts-opponent-template-container")
				:node(htmlCreate("i")
				:wikitext(args.name or "")
				:addClass("brkts-opponent-literal")
				:cssText([[margin-left: 3px;
					color: rgb(55,55,55);
					margin-top: 1px;
					width: 100%;
					display: inline-block;
					overflow: hidden;
					text-overflow: ellipsis;]]))
			wrapper:node(container)
		else
			wrapper:node(htmlCreate("div"):addClass("brkts-team-template-container"))
		end

		-- add scores
		local score, score2 = p._getScore(args)
		wrapper:node(htmlCreate("div")
			:addClass("brkts-opponent-score")
			:wikitext(score or ""))
		if score2 ~= nil then
			wrapper:node(htmlCreate("div")
				:addClass("brkts-opponent-score")
				:wikitext(score2 or ""))
		end
		if (tonumber((args.placement2 or args.placement) or 0) == 1) then
			wrapper:addClass("brkts-opponent-win")
		end
	elseif utils.string.startsWith(displayType, "matchlist") then
		if displayType == "matchlist-left" then
			local team = p._getTeamMatchList(frame, args.template, "left")
			return htmlCreate("div")
				:addClass("brkts-matchlist-opponent-template-container")
				:css("display","inline")
				:node(team)
		elseif displayType == "matchlist-right" then
			local team = p._getTeamMatchList(frame, args.template, "right")
			return htmlCreate("div")
				:addClass("brkts-matchlist-opponent-template-container")
				:css("display","inline")
				:node(team)
		elseif displayType == "matchlist-left-score" or displayType == "matchlist-right-score" then
			local score = p._getScore(args)
			return score
		end
	else
		-- add scores
		local score, score2 = p._getScore(args)
		wrapper:node(htmlCreate("div")
			:addClass("brkts-opponent-score")
			:wikitext(score))
		if score2 ~= nil then
				wrapper:node(htmlCreate("div")
				:addClass("brkts-opponent-score")
				:wikitext(score2))
		end
		if (tonumber((args.placement2 or args.placement) or 0) == 1) then
			wrapper:addClass("brkts-opponent-win")
		end
	end
	return wrapper
end

function p._getTeam(frame, template)
	local teamExists = mw.ext.TeamTemplate.teamexists(template)
	local team = {
		bracket = teamExists and mw.ext.TeamTemplate.teambracket(template) or
			utils.frame.protectedExpansion(frame, "TeamBracket", { template }),
		short = teamExists and mw.ext.TeamTemplate.teamshort(template) or
			utils.frame.protectedExpansion(frame, "TeamShort", { template })
	}
	return team
end

function p._getTeamMatchList(frame, template, side)
	local teamExists = mw.ext.TeamTemplate.teamexists(template)
	if side == "left" then
		return teamExists and mw.ext.TeamTemplate.team2short(template) or
			utils.frame.protectedExpansion(frame, "Team2Short", { template })
	elseif side == "right" then
		return teamExists and mw.ext.TeamTemplate.teamshort(template) or
			utils.frame.protectedExpansion(frame, "TeamShort", { template })
	end
end

function p._getScore(args)
	local score = ""
	if args.status == "S" then
		score = args.score
	elseif args.status ~= "" then
		score = args.status
	end
	local score2 = nil
	if args.score2 ~= nil and args.score2 ~= "null" then
		score2 = ""
		if args.status2 == "S" then
			score2 = args.score2
		elseif args.status2 ~= "" then
			score2 = args.status2
		end
	elseif args.score2 == "null" then
		score2 = ""
	end
	return score, score2
end

return p

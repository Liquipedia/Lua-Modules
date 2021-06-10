local p = {}

local Class = require('Module:Class')
local String = require('Module:String')
local Template = require('Module:Template')

local getArgs = require("Module:Arguments").getArgs
local String = require("Module:StringUtils")

local OpponentDisplay = Class.new(
	function(opponent)
		opponent.root = mw.html.create('div')
		opponent.root:addClass('brkts-opponent-wrapper')
	end
)

function OpponentDisplay:addScores(score, score2, placement, placement2)
	if self.root == nil then
		return
	end

	local scoreTag = mw.html.create('div')
	scoreTag:addClass('brkts-opponent-score')
			:wikitext(score or '')
	self.root:node(scoreTag)

	if score2 ~= nil then
		local scoreTag2 = mw.html.create('div')
		scoreTag2
			:addClass('brkts-opponent-score')
			:wikitext(score2 or '')
		self.root:node(scoreTag2)
	end

	if tonumber((placement2 or placement) or 0) == 1 then
		self.root:addClass('brkts-opponent-win')
	end
end

local BracketOpponentDisplay = Class.new(
	OpponentDisplay,
	function(bracket, frame, opponentType, name, flag)
		if String.isEmpty(name) then
			bracket.root = ''
			return
		end

		bracket.content = mw.html.create('div')
		bracket.content:addClass('brkts-opponent-template-container')

		if opponentType == 'team' then
			bracket:createTeam(frame, name)
		elseif opponentType == 'solo' then
			bracket:createSolo(frame, name, flag)
		elseif opponentType == 'literal' then
			bracket:createLiteral(name)
		end

		bracket.root:node(bracket.content)
	end
)

function BracketOpponentDisplay:createTeam(frame, name)
	local team = p._getTeam(frame, name)

	local teamBracket = mw.html.create('div')
	teamBracket :addClass('hidden-xs')
				:wikitext(team.bracket)

	local teamShort = mw.html.create('div')
	teamShort
		:addClass('visible-xs')
		:wikitext(team.short)
	self.content:node(teamBracket):node(teamShort)
end

function BracketOpponentDisplay:createSolo(frame, name, flag)
	self.content:addClass('brkts-player-container')
				:wikitext(Template.safeExpand(frame, "Player", {
					name,
					flag = flag
				}))
end

function BracketOpponentDisplay:createLiteral(name)
	local literal = mw.html.create('i')
	literal :addClass('brkts-opponent-literal')
			:wikitext(name or '')
			:css({
				['margin-left'] = '3px',
				['margin-top'] = '1px',
				['color'] = 'rgb(55, 55, 55)',
				['width'] = '100%',
				['display'] = 'inline-block',
				['overflow'] = 'hidden',
				['text-overflow'] = 'ellipsis',
			})
	self.content:node(literal)
end

function p.get(frame)
	return p.luaGet(frame, getArgs(frame))
end

function p.luaGet(frame, args)
	local displayType = args.displaytype

	if displayType == "bracket" then
		local name = ''

		if args.type == 'team' then
			name = args.template
		elseif args.type == 'solo' then
			name = args.match2player1_name
		else
			name = args.name
		end

		if name == nil or name == '' then
			return ''
		end

		local bracket = BracketOpponentDisplay(frame, args.type, name, args.match2player1_flag)
		local score1, score2 = p._getScore(args)
		bracket:addScores(score1, score2, args.placement, args.placement2)
		return bracket.root

	elseif String.startsWith(displayType, "matchlist") then

		return p._createMatchListOpponent(frame, displayType, args.template, p._getScore(args))

	else
		local opponent = OpponentDisplay()
		local score1, score2 = p._getScore(args)
		opponent:addScores(score1, score2, args.placement, args.placement2)
		return opponent.root
	end
end

function p._getTeam(frame, template)
	local teamExists = mw.ext.TeamTemplate.teamexists(template)
	local team = {
		bracket = teamExists and mw.ext.TeamTemplate.teambracket(template) or Template.safeExpand(frame, "TeamBracket", { template }),
		short = teamExists and mw.ext.TeamTemplate.teamshort(template) or Template.safeExpand(frame, "TeamShort", { template })
	}
	return team
end

function p._getTeamMatchList(frame, template, side)
	local teamExists = mw.ext.TeamTemplate.teamexists(template)
	if side == "left" then
		return teamExists and mw.ext.TeamTemplate.team2short(template) or Template.safeExpand(frame, "Team2Short", { template })
	elseif side == "right" then
		return teamExists and mw.ext.TeamTemplate.teamshort(template) or Template.safeExpand(frame, "TeamShort", { template })
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

function p._createMatchListOpponent(frame, displayType, name, score)
	if displayType == 'matchlist-left' then
		if String.isEmpty(name) then
			return ''
		end

		local team = p._getTeamMatchList(frame, name, 'left')
		return mw.html.create('div')
			:addClass('brkts-matchlist-opponent-template-container')
			:css('display', 'inline')
			:node(team)
	elseif displayType == 'matchlist-right' then
		if String.isEmpty(name) then
			return ''
		end

		local team = p._getTeamMatchList(frame, name, 'right')
		return mw.html.create('div')
			:addClass('brkts-matchlist-opponent-template-container')
			:css('display', 'inline')
			:node(team)
	elseif displayType == 'matchlist-left-score' or displayType == 'matchlist-right-score' then
		return score
	end
end

return p

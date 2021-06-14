local p = {}

local Class = require('Module:Class')
local Template = require('Module:Template')

local getArgs = require("Module:Arguments").getArgs
local String = require("Module:StringUtils")

local BaseOpponentDisplay = Class.new(
	function(opponent)
		opponent.root = mw.html.create('div')
		opponent.root:addClass('brkts-opponent-wrapper')
	end
)

function BaseOpponentDisplay:addScores(score, score2, placement, placement2)
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
	BaseOpponentDisplay,
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
		local name

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

	else
		local opponent = BaseOpponentDisplay()
		local score1, score2 = p._getScore(args)
		opponent:addScores(score1, score2, args.placement, args.placement2)
		return opponent.root
	end
end

function p._getTeam(frame, template)
	local teamExists = mw.ext.TeamTemplate.teamexists(template)
	local team = {
		bracket = teamExists
			and mw.ext.TeamTemplate.teambracket(template)
			or Template.safeExpand(frame, "TeamBracket", { template }),
		short = teamExists
			and mw.ext.TeamTemplate.teamshort(template)
			or Template.safeExpand(frame, "TeamShort", { template })
	}
	return team
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

--local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local PlayerDisplay = require('Module:Player/Display')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local OpponentDisplay = Table.merge(p, {propTypes = {}, types = {}})

OpponentDisplay.types.TeamStyle = TypeUtil.literalUnion('standard', 'short', 'bracket')

OpponentDisplay.propTypes.InlineOpponent = {
	flip = 'boolean?',
	opponent = MatchGroupUtil.types.GameOpponent,
	showFlag = 'boolean?',
	showLink = 'boolean?', -- does not affect opponent.type == 'team'
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
}

--[[
Displays an opponent as an inline element. Useful for describing opponents in
prose.
]]
function OpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineOpponent, {maxDepth = 2})
	local opponent = props.opponent

	if opponent.type == 'team' then
		return OpponentDisplay.InlineTeam({
			flip = props.flip,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})

	elseif opponent.type == 'literal' then
		return opponent.name or ''

	elseif opponent.type == 'solo' then
		return OpponentDisplay.PlayerInlineOpponent(props)

	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end
end

OpponentDisplay.propTypes.BlockOpponent = {
	flip = 'boolean?',
	opponent = MatchGroupUtil.types.GameOpponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showFlag = 'boolean?',
	showLink = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
}

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
function OpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockOpponent, {maxDepth = 2})
	local opponent = props.opponent

	if opponent.type == 'team' then
		return OpponentDisplay.BlockTeam({
			flip = props.flip,
			overflow = props.overflow,
			showLink = props.showLink,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' then
		return OpponentDisplay.BlockLiteral({
			flip = props.flip,
			name = opponent.name or '',
			overflow = props.overflow,
		})
	elseif opponent.type == 'solo' then
		return PlayerDisplay.BlockPlayer({
			flip = props.flip,
			overflow = props.overflow,
			player = opponent.players[1],
			showFlag = props.showFlag,
			showLink = props.showLink,
		})
	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end
end

OpponentDisplay.propTypes.InlineTeam = {
	flip = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	template = 'string',
}

--[[
Displays a team as an inline element.
]]
function OpponentDisplay.InlineTeam(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineTeam)

	local teamExists = mw.ext.TeamTemplate.teamexists(props.template)
	if props.style == 'standard' or not props.style then
		if not props.flip then
			return teamExists
				and mw.ext.TeamTemplate.team(props.template)
				or Template.safeExpand(mw.getCurrentFrame(), 'Team', {props.template})
		else
			return teamExists
				and mw.ext.TeamTemplate.team2(props.template)
				or Template.safeExpand(mw.getCurrentFrame(), 'Team2', {props.template})
		end
	elseif props.style == 'short' then
		if not props.flip then
			return teamExists
				and mw.ext.TeamTemplate.teamshort(props.template)
				or Template.safeExpand(mw.getCurrentFrame(), 'TeamShort', {props.template})
		else
			return teamExists
				and mw.ext.TeamTemplate.team2short(props.template)
				or Template.safeExpand(mw.getCurrentFrame(), 'Team2Short', {props.template})
		end
	elseif props.style == 'bracket' then
		if not props.flip then
			return teamExists
				and mw.ext.TeamTemplate.teambracket(props.template)
				or Template.safeExpand(mw.getCurrentFrame(), 'TeamBracket', {props.template})
		else
			error('Flipped style=bracket is not supported')
		end
	end
end

OpponentDisplay.propTypes.BlockTeam = {
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showLink = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	template = 'string',
}

--[[
Displays a team as a block element. The width of the component is determined by
its layout context, and not of the team name.
]]
function OpponentDisplay.BlockTeam(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockTeam)
	local style = props.style or 'standard'

	local raw = mw.ext.TeamTemplate.raw(props.template)
	if not raw then
		return mw.html.create('div'):addClass('error')
			:wikitext('No team template exists for name ' .. props.template)
	end

	local displayName = style == 'standard' and raw.name
		or style == 'short' and raw.shortname
		or style == 'bracket' and raw.bracketname

	local nameNode = mw.html.create('span'):addClass('name')
		:wikitext(props.showLink ~= false
			and '[[' .. raw.page .. '|' .. displayName .. ']]'
			or displayName
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	return mw.html.create('div'):addClass('block-team')
		:addClass(props.showLink == false and 'block-team-hide-link' or nil)
		:addClass(props.flip and 'flipped' or nil)
		:node(mw.ext.TeamTemplate.teamicon(props.template))
		:node(nameNode)
end

OpponentDisplay.propTypes.BlockLiteral = {
	flip = 'boolean?',
	name = 'string',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
}

--[[
Displays the name of a literal opponent as a block element.
]]
function OpponentDisplay.BlockLiteral(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockLiteral)

	return DisplayUtil.applyOverflowStyles(mw.html.create('div'), props.overflow or 'wrap')
		:addClass('brkts-opponent-block-literal')
		:addClass(props.flip and 'flipped' or nil)
		:node(props.name)
end

--[[
Displays the first score or status of the opponent, as a string.
]]
function OpponentDisplay.InlineScore(opponent)
	if opponent.status == 'S' then
		if opponent.score == 0 and DisplayHelper.opponentIsTBD(opponent) then
			return ''
		else
			return opponent.score ~= -1 and tostring(opponent.score) or ''
		end
	else
		return opponent.status or ''
	end
end

--[[
Displays the second score or status of the opponent, as a string.
]]
function OpponentDisplay.InlineScore2(opponent)
	if opponent.status2 == 'S' then
		if opponent.score2 == 0 and DisplayHelper.opponentIsTBD(opponent) then
			return ''
		else
			return opponent.score2 ~= -1 and tostring(opponent.score2) or ''
		end
	else
		return opponent.status2 or ''
	end
end

OpponentDisplay.propTypes.BracketScore = {
	isWinner = 'boolean?',
	scoreText = 'any',
}

--[[
Displays a score within the context of a bracket opponent entry.
]]
function OpponentDisplay.BracketScore(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BracketScore)

	local scoreText = props.scoreText
	if props.isWinner then
		scoreText = '<b>' .. scoreText .. '</b>'
	end

	return mw.html.create('div'):addClass('brkts-opponent-score-outer')
		:node(
			mw.html.create('div'):addClass('brkts-opponent-score-inner')
				:wikitext(scoreText)
		)
end

return Class.export(OpponentDisplay)

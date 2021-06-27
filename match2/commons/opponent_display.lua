local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local PlayerDisplay = require('Module:Player/Display')
local Table = require('Module:Table')
local Template = require('Module:Template')
local TypeUtil = require('Module:TypeUtil')

local OpponentDisplay = {propTypes = {}, types = {}}

OpponentDisplay.types.TeamStyle = TypeUtil.literalUnion('standard', 'short', 'bracket')

--[[
Display component for an opponent entry appearing in a bracket match.
]]
OpponentDisplay.BracketOpponentEntry = Class.new(
	function(self, opponent)
		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')

		if opponent.type == 'team' then
			self:createTeam(opponent.template or 'tbd')
		elseif opponent.type == 'solo' then
			self:createPlayer(opponent.players[1])
		elseif opponent.type == 'literal' then
			self:createLiteral(opponent.name or '')
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

function OpponentDisplay.BracketOpponentEntry:createTeam(template)
	local bracketStyleNode = OpponentDisplay.BlockTeamContainer({
		overflow = 'ellipsis',
		showLink = false,
		style = 'bracket',
		template = template,
	})
		:addClass('hidden-xs')
	local shortStyleNode = OpponentDisplay.BlockTeamContainer({
		overflow = 'hidden',
		showLink = false,
		style = 'short',
		template = template,
	})
		:addClass('visible-xs')
	self.content:node(bracketStyleNode):node(shortStyleNode)
end

function OpponentDisplay.BracketOpponentEntry:createPlayer(player)
	local playerNode = PlayerDisplay.BlockPlayer({
		player = player,
		overflow = 'ellipsis',
	})
	self.content:node(playerNode)
end

function OpponentDisplay.BracketOpponentEntry:createLiteral(name)
	local literal = OpponentDisplay.BlockLiteral({
		name = name,
		overflow = 'ellipsis',
	})
	self.content:node(literal)
end

function OpponentDisplay.BracketOpponentEntry:addScores(opponent)
	local score1Node = OpponentDisplay.BracketScore({
		isWinner = opponent.placement == 1 or opponent.advances,
		scoreText = OpponentDisplay.InlineScore(opponent),
	})
	self.root:node(score1Node)

	local score2Node
	if opponent.score2 then
		score2Node = OpponentDisplay.BracketScore({
			isWinner = opponent.placement2 == 1,
			scoreText = OpponentDisplay.InlineScore2(opponent),
		})
	end
	self.root:node(score2Node)

	if (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances then
		self.root:addClass('brkts-opponent-win')
	end
end

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
		return OpponentDisplay.InlineTeamContainer({
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
		return OpponentDisplay.BlockTeamContainer({
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

OpponentDisplay.propTypes.InlineTeamContainer = {
	flip = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	template = 'string',
}

--[[
Displays a team as an inline element. The team is specified by a template.
]]
function OpponentDisplay.InlineTeamContainer(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineTeamContainer)

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

OpponentDisplay.propTypes.InlineTeam = {
	flip = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	team = MatchGroupUtil.types.Team,
}

--[[
Displays a team as an inline element. The team is specified by a team struct.
Only the default icon is supported.
]]
function OpponentDisplay.InlineTeam(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineTeam)
	return OpponentDisplay.InlineTeamContainer(Table.merge(props, {
		template = 'default',
	}))
		:gsub('DefaultPage', props.team.pageName)
		:gsub('DefaultName', props.team.displayName)
		:gsub('DefaultShort', props.team.shortName)
		:gsub('DefaultBracket', props.team.bracketName)
end

OpponentDisplay.propTypes.BlockTeamContainer = {
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showLink = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	template = 'string',
}

--[[
Displays a team as a block element. The width of the component is determined by
its layout context, and not of the team name. The team is specified by template.
]]
function OpponentDisplay.BlockTeamContainer(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockTeamContainer)

	local team = MatchGroupUtil.fetchTeam(props.template)
	if not team then
		return mw.html.create('div'):addClass('error')
			:wikitext('No team template exists for name ' .. props.template)
	end

	return OpponentDisplay.BlockTeam(Table.merge(props, {
		icon = mw.ext.TeamTemplate.teamicon(props.template),
		team = team,
	}))
end

OpponentDisplay.propTypes.BlockTeam = {
	flip = 'boolean?',
	icon = 'any',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showLink = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	team = MatchGroupUtil.types.Team,
}

--[[
Displays a team as a block element. The width of the component is determined by
its layout context, and not of the team name. The team is specified by a team
struct and icon wikitext.
]]
function OpponentDisplay.BlockTeam(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockTeam)
	local style = props.style or 'standard'

	local displayName = style == 'standard' and props.team.displayName
		or style == 'short' and props.team.shortName
		or style == 'bracket' and props.team.bracketName

	local nameNode = mw.html.create('span'):addClass('name')
		:wikitext(props.showLink ~= false and props.team.pageName
			and '[[' .. props.team.pageName .. '|' .. displayName .. ']]'
			or displayName
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	return mw.html.create('div'):addClass('block-team')
		:addClass(props.showLink == false and 'block-team-hide-link' or nil)
		:addClass(props.flip and 'flipped' or nil)
		:node(props.icon)
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

---
-- @Liquipedia
-- wiki=commons
-- page=Module:OpponentDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Template = require('Module:Template')
local TypeUtil = require('Module:TypeUtil')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})

local zeroWidthSpace = '&#8203;'

local OpponentDisplay = {propTypes = {}, types = {}}

OpponentDisplay.types.TeamStyle = TypeUtil.literalUnion('standard', 'short', 'bracket', 'hybrid', 'icon')
---@alias teamStyle 'standard'|'short'|'bracket'|'hybrid'|'icon'

---Display component for an opponent entry appearing in a bracket match.
---@class BracketOpponentEntry
---@operator call(...): BracketOpponentEntry
---@field content Html
---@field root Html
OpponentDisplay.BracketOpponentEntry = Class.new(
	---@param self self
	---@param opponent standardOpponent
	---@param options {forceShortName: boolean}
	function(self, opponent, options)
		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')

		if opponent.type == Opponent.team then
			self:createTeam(opponent.template or 'tbd', options)
		elseif Opponent.typeIsParty(opponent.type) then
			self:createPlayers(opponent)
		elseif opponent.type == Opponent.literal then
			self:createLiteral(opponent.name or '')
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

---Creates team display as BracketOpponentEntry
---@param template string
---@param options {forceShortName: boolean}
function OpponentDisplay.BracketOpponentEntry:createTeam(template, options)
	options = options or {}
	local forceShortName = options.forceShortName

	local opponentNode = OpponentDisplay.BlockTeamContainer({
		showLink = false,
		style = forceShortName and 'short' or 'hybrid',
		template = template,
	})

	self.content:node(opponentNode)
end

---Creates party display as BracketOpponentEntry
---@param opponent standardOpponent
function OpponentDisplay.BracketOpponentEntry:createPlayers(opponent)
	local playerNode = OpponentDisplay.BlockPlayers({
		opponent = opponent,
		overflow = 'ellipsis',
		showLink = false,
	})
	self.content:node(playerNode)
end

---Creates literal display as BracketOpponentEntry
---@param name string
function OpponentDisplay.BracketOpponentEntry:createLiteral(name)
	local literal = OpponentDisplay.BlockLiteral({
		name = name,
		overflow = 'ellipsis',
	})
	self.content:node(literal)
end

---Adds scores to BracketOpponentEntry
---@param opponent standardOpponent
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
		self.content:addClass('brkts-opponent-win')
	end
end

OpponentDisplay.propTypes.InlineOpponent = {
	flip = 'boolean?',
	opponent = MatchGroupUtil.types.GameOpponent,
	showFlag = 'boolean?', -- only affects parties
	showLink = 'boolean?', -- only affects parties
	dq = 'boolean?', -- only affects parties
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle), -- only affects Opponent.team
}

---@class InlineOpponentProps
---@field flip boolean?
---@field opponent standardOpponent
---@field showFlag boolean?
---@field showLink boolean?
---@field dq boolean?
---@field teamStyle teamStyle?

---Displays an opponent as an inline element. Useful for describing opponents in prose.
---@param props InlineOpponentProps
---@return Html|string|nil
function OpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineOpponent, {maxDepth = 2})
	local opponent = props.opponent

	if opponent.type == Opponent.team then
		return OpponentDisplay.InlineTeamContainer({
			flip = props.flip,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == Opponent.literal then
		return opponent.name or ''
	elseif Opponent.typeIsParty(opponent.type) then
		return OpponentDisplay.InlinePlayers(props)
	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end
end

---@param props InlineOpponentProps
---@return Html
function OpponentDisplay.InlinePlayers(props)
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		return tostring(PlayerDisplay.InlinePlayer(Table.merge(props, {player = player})))
	end)

	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	return mw.html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

OpponentDisplay.propTypes.BlockOpponent = {
	flip = 'boolean?',
	opponent = MatchGroupUtil.types.GameOpponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showPlayerTeam = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	abbreviateTbd = 'boolean?',
}

---@class BlockOpponentProps
---@field flip boolean?
---@field opponent standardOpponent
---@field overflow OverflowModes?
---@field showFlag boolean?
---@field showLink boolean?
---@field showPlayerTeam boolean?
---@field abbreviateTbd boolean?
---@field playerClass string?
---@field teamStyle teamStyle?
---@field dq boolean?
---@field note string|number|nil

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
---@param props BlockOpponentProps
---@return Html
function OpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockOpponent, {maxDepth = 2})
	local opponent = props.opponent
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.team then
		return OpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == Opponent.literal then
		return OpponentDisplay.BlockLiteral({
			flip = props.flip,
			name = opponent.name or '',
			overflow = props.overflow,
		})
	elseif Opponent.typeIsParty(opponent.type) then
		return OpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end
end

---@class BlockPlayerProps
---@field flip boolean?
---@field opponent {players: standardPlayer[]?}
---@field overflow OverflowModes?
---@field showFlag boolean?
---@field showLink boolean?
---@field showPlayerTeam boolean?
---@field abbreviateTbd boolean?
---@field playerClass string?
---@field dq boolean?
---@field note string|number|nil

---@param props BlockPlayerProps
---@return Html
function OpponentDisplay.BlockPlayers(props)
	local opponent = props.opponent

	--only apply note to first player, hence extract it here
	local note = Table.extract(props, 'note')

	local playerNodes = Array.map(opponent.players, function(player, playerIndex)
		return PlayerDisplay.BlockPlayer(Table.merge(props, {
			player = player,
			team = player.team,
			note = playerIndex == 1 and note or nil,
		})):addClass(props.playerClass)
	end)

	local playersNode = mw.html.create('div')
		:addClass(props.showPlayerTeam and 'player-has-team' or nil)
	for _, playerNode in ipairs(playerNodes) do
		playersNode:node(playerNode)
	end

	return playersNode
end

OpponentDisplay.propTypes.InlineTeamContainer = {
	flip = 'boolean?',
	style = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	template = 'string',
}

---Displays a team as an inline element. The team is specified by a template.
---@param props {flip: boolean?, template: string, style: teamStyle?}
---@return string?
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
---@param props {flip: boolean?, style: teamStyle?, team: standardTeamProps}
---@return string
function OpponentDisplay.InlineTeam(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineTeam)
	return (OpponentDisplay.InlineTeamContainer(Table.merge(props, {
		template = 'default',
	}))
		:gsub('DefaultPage', props.team.pageName)
		:gsub('DefaultName', Logic.emptyOr(props.team.displayName, zeroWidthSpace) --[[@as string]])
		:gsub('DefaultShort', props.team.shortName)
		:gsub('DefaultBracket', props.team.bracketName))
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
---@param props {flip: boolean?, overflow: OverflowModes?, showLink: boolean?, style: teamStyle?, template: string}
---@return Html
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

---@class blockTeamProps
---@field flip boolean
---@field icon string
---@field overflow OverflowModes?
---@field showLink boolean?
---@field style teamStyle?
---@field team standardTeamProps
---@field dq boolean?

--[[
Displays a team as a block element. The width of the component is determined by
its layout context, and not of the team name. The team is specified by a team
struct and icon wikitext.
]]
---@param props blockTeamProps
---@return Html
function OpponentDisplay.BlockTeam(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockTeam)
	local style = props.style or 'standard'

	local function createNameNode(name)
		return mw.html.create(props.dq and 's' or 'span'):addClass('name')
			:wikitext(props.showLink ~= false and props.team.pageName
				and '[[' .. props.team.pageName .. '|' .. name .. ']]'
				or name
			)
	end

	local displayNameNode = createNameNode(props.team.displayName)
	local bracketNameNode = createNameNode(props.team.bracketName)
	local shortNameNode = createNameNode(props.team.shortName)

	local icon = props.showLink
		and props.icon
		or DisplayUtil.removeLinkFromWikiLink(props.icon)

	local blockNode = mw.html.create('div'):addClass('block-team')
		:addClass(props.flip and 'flipped' or nil)
		:node(icon)

	if style == 'standard' then
		DisplayUtil.applyOverflowStyles(displayNameNode, props.overflow or 'ellipsis')
		blockNode:node(displayNameNode)
	elseif style == 'bracket' then
		DisplayUtil.applyOverflowStyles(bracketNameNode, props.overflow or 'ellipsis')
		blockNode:node(bracketNameNode)
	elseif style == 'short' then
		DisplayUtil.applyOverflowStyles(shortNameNode, props.overflow or 'ellipsis')
		blockNode:node(shortNameNode)
	elseif style == 'hybrid' then
		DisplayUtil.applyOverflowStyles(bracketNameNode, 'ellipsis')
		DisplayUtil.applyOverflowStyles(shortNameNode, 'hidden')
		blockNode:node(bracketNameNode:addClass('hidden-xs'))
		blockNode:node(shortNameNode:addClass('visible-xs'))
	end

	return blockNode
end

OpponentDisplay.propTypes.BlockLiteral = {
	flip = 'boolean?',
	name = 'string',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
}

---Displays the name of a literal opponent as a block element.
---@param props {flip: boolean?, name: string, overflow: OverflowModes}
---@return Html
function OpponentDisplay.BlockLiteral(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockLiteral)

	return DisplayUtil.applyOverflowStyles(mw.html.create('div'), props.overflow or 'wrap')
		:addClass('brkts-opponent-block-literal')
		:addClass(props.flip and 'flipped' or nil)
		:node(Logic.emptyOr(props.name, zeroWidthSpace))
end

OpponentDisplay.propTypes.BlockScore = {
	isWinner = 'boolean?',
	scoreText = 'any',
}

---Displays a score within the context of a block element.
---@param props {isWinner: boolean?, scoreText: string|number?}
---@return Html
function OpponentDisplay.BlockScore(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockScore)

	local scoreText = props.scoreText
	if props.isWinner then
		scoreText = '<b>' .. scoreText .. '</b>'
	end

	return mw.html.create('div'):wikitext(scoreText)
end

---Displays the first score or status of the opponent, as a string.
---@param opponent standardOpponent
---@return string
function OpponentDisplay.InlineScore(opponent)
	if opponent.status == 'S' then
		if opponent.score == 0 and Opponent.isTbd(opponent) then
			return ''
		else
			return opponent.score ~= -1 and tostring(opponent.score) or ''
		end
	else
		return opponent.status or ''
	end
end

---Displays the second score or status of the opponent, as a string.
---@param opponent standardOpponent
---@return string
function OpponentDisplay.InlineScore2(opponent)
	if opponent.status2 == 'S' then
		if opponent.score2 == 0 and Opponent.isTbd(opponent) then
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

---Displays a score within the context of a bracket opponent entry.
---@param props {isWinner: boolean?, scoreText: string|number?}
---@return Html
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

---
-- @Liquipedia
-- page=Module:OpponentDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local Logic = Lua.import('Module:Logic')
local Math = Lua.import('Module:MathUtil')
local Table = Lua.import('Module:Table')
local TypeUtil = Lua.import('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Html = Lua.import('Module:Widget/Html')
local BlockTeam = Lua.import('Module:Widget/TeamDisplay/Block')
local TeamInline = Lua.import('Module:Widget/TeamDisplay/Inline')

local zeroWidthSpace = '&#8203;'

---@class OpponentDisplay
local OpponentDisplay = {propTypes = {}, types = {}}

OpponentDisplay.types.TeamStyle = TypeUtil.literalUnion('standard', 'short', 'bracket', 'hybrid', 'icon', 'dynamic')
---@alias teamStyle 'standard'|'short'|'bracket'|'hybrid'|'icon'|'dynamic'

---@class InlineOpponentProps
---@field flip boolean?
---@field opponent standardOpponent
---@field showFlag boolean?
---@field showLink boolean?
---@field dq boolean?
---@field note string|number|nil
---@field teamStyle teamStyle?
---@field showFaction boolean?
---@field showTbd boolean?

---Displays an opponent as an inline element. Useful for describing opponents in prose.
---@param props InlineOpponentProps
---@return Html
function OpponentDisplay.InlineOpponent(props)
	local opponent = props.opponent

	local opponentNode
	if opponent.type == Opponent.team then
		if props.showTbd == false and Opponent.isTbd(opponent) then
			return mw.html.create()
		end
		opponentNode = OpponentDisplay.InlineTeamContainer{
			flip = props.flip,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		}
	elseif opponent.type == Opponent.literal then
		opponentNode = opponent.name or ''
	elseif Opponent.typeIsParty(opponent.type) then
		opponentNode = OpponentDisplay.InlinePlayers(props)
	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end

	return mw.html.create()
		:node(opponentNode)
		:node(props.note and mw.html.create('sup'):addClass('note'):wikitext(props.note) or nil)
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

---@class BlockOpponentProps
---@field flip boolean?
---@field opponent standardOpponent
---@field overflow OverflowModes?
---@field showFlag boolean?
---@field showLink boolean?
---@field showPlayerTeam boolean?
---@field playerClass string?
---@field teamStyle teamStyle?
---@field dq boolean?
---@field note string|number|nil
---@field showFaction boolean?
---@field showTbd boolean?
---@field additionalClasses string[]?

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
---@param props BlockOpponentProps
---@return Renderable
function OpponentDisplay.BlockOpponent(props)
	local opponent = props.opponent
	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.team then
		if props.showTbd == false and Opponent.isTbd(opponent) then
			return Html.Fragment{}
		end
		return OpponentDisplay.BlockTeamContainer{
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
			additionalClasses = props.additionalClasses,
			note = props.note,
		}
	elseif opponent.type == Opponent.literal then
		return OpponentDisplay.BlockLiteral{
			flip = props.flip,
			name = opponent.name or '',
			overflow = props.overflow,
			additionalClasses = props.additionalClasses
		}
	elseif Opponent.typeIsParty(opponent.type) then
		return OpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end
end

---@param props BlockOpponentProps
---@return VNode
function OpponentDisplay.BlockPlayers(props)
	return Html.Div{
		classes = Array.extend('block-players-wrapper', props.additionalClasses),
		children = OpponentDisplay.getBlockPlayerNodes(props)
	}
end

---@param props BlockOpponentProps
---@return VNode[]
function OpponentDisplay.getBlockPlayerNodes(props)
	local opponent = props.opponent

	--only apply note to first player, hence extract it here
	local note = Table.extract(props, 'note')

	return Array.map(opponent.players, function(player, playerIndex)
		return PlayerDisplay.BlockPlayer(Table.merge(props, {
			player = player,
			team = player.team,
			note = playerIndex == 1 and note or nil,
		}))
	end)
end

---Displays a team as an inline element. The team is specified by a template.
---@param props {flip: boolean?, template: string, date: number|string?, style: teamStyle?}
---@return VNode
function OpponentDisplay.InlineTeamContainer(props)
	local style = props.style or 'standard'
	TypeUtil.assertValue(style, OpponentDisplay.types.TeamStyle)
	assert(style ~= 'dynamic', 'style=dynamic is not supported inline')
	assert(style ~= 'bracket' or not props.flip, 'Flipped style=bracket is not supported')
	return TeamInline{name = props.template, date = props.date, flip = props.flip, displayType = style}
end

--[[
Displays a team as a block element. The width of the component is determined by
its layout context, and not of the team name. The team is specified by template.
]]
---@param props {flip: boolean?, overflow: OverflowModes?, showLink: boolean?,
---style: teamStyle?, template: string, additionalClasses: string[]?, note: string|number?}
---@return VNode
function OpponentDisplay.BlockTeamContainer(props)
	local style = props.style or 'standard'
	TypeUtil.assertValue(style, OpponentDisplay.types.TeamStyle)
	return BlockTeam{
		name = props.template,
		flip = props.flip,
		style = style,
		overflow = props.overflow,
		noLink = not props.showLink,
		additionalClasses = props.additionalClasses,
		note = props.note,
	}
end

OpponentDisplay.propTypes.BlockLiteral = {
	flip = 'boolean?',
	name = 'string',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
}

---Displays the name of a literal opponent as a block element.
---@param props {flip: boolean?, name: string, overflow: OverflowModes, additionalClasses: string[]?}
---@return VNode
function OpponentDisplay.BlockLiteral(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockLiteral)

	return Html.Div{
		classes = Array.extend(
			'brkts-opponent-block-literal',
			props.flip and 'flipped' or nil,
			props.additionalClasses
		),
		css = DisplayUtil.getOverflowStyles(props.overflow or 'wrap'),
		children = Logic.emptyOr(props.name, zeroWidthSpace)
	}
end

OpponentDisplay.propTypes.BlockScore = {
	additionalClasses = TypeUtil.optional(TypeUtil.array('string')),
	isWinner = 'boolean?',
	scoreText = 'any',
}

---Displays a score within the context of a block element.
---@param props {isWinner: boolean?, scoreText: string|number?, additionalClasses: string[]?}
---@return VNode
function OpponentDisplay.BlockScore(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockScore)

	local scoreText = props.scoreText

	return Html.Div{
		classes = props.additionalClasses,
		children = props.isWinner and Html.B{children = scoreText} or scoreText
	}
end

---Displays the first score or status of the opponent, as a string.
---@param opponent standardOpponent
---@return string
function OpponentDisplay.InlineScore(opponent)
	if opponent.status == 'S' then
		if opponent.score == 0 and Opponent.isTbd(opponent) then
			return ''
		elseif opponent.score == -1 then
			return ''
		else
			return tostring(Math.round(opponent.score, 2))
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

return OpponentDisplay

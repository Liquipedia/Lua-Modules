---
-- @Liquipedia
-- wiki=commons
-- page=Module:OpponentDisplay/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local Faction = Lua.import('Module:Faction', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
local StarcraftOpponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})
local StarcraftPlayerDisplay = Lua.import('Module:Player/Display/Starcraft', {requireDevIfEnabled = true})

local html = mw.html

--Display components for opponents used by the starcraft and starcraft 2 wikis
local StarcraftOpponentDisplay = {propTypes = {}, types={}}

StarcraftOpponentDisplay.propTypes.InlineOpponent = {
	flip = 'boolean?',
	opponent = StarcraftMatchGroupUtil.types.GameOpponent,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
}

---@class StarcraftInlineOpponentProps: InlineOpponentProps
---@field opponent StarcraftStandardOpponent
---@field showRace boolean?

---Displays an opponent as an inline element. Useful for describing opponents in prose.
---@param props StarcraftInlineOpponentProps
---@return Html|string|nil
function StarcraftOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, StarcraftOpponentDisplay.propTypes.InlineOpponent)
	local opponent = props.opponent

	if opponent.type == 'team' then
		return StarcraftOpponentDisplay.InlineTeamContainer({
			flip = props.flip,
			showLink = props.showLink,
			style = props.teamStyle,
			team = opponent.team,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' then
		return OpponentDisplay.InlineOpponent(props)
	else -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return StarcraftOpponentDisplay.PlayerInlineOpponent(props)
	end
end

StarcraftOpponentDisplay.propTypes.BlockOpponent = {
	flip = 'boolean?',
	opponent = StarcraftMatchGroupUtil.types.GameOpponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showPlayerTeam = 'boolean?',
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	playerClass = 'string?',
	abbreviateTbd = 'boolean?',
}

---@class StarcraftBlockOpponentProps: BlockOpponentProps
---@field opponent StarcraftStandardOpponent
---@field showRace boolean?

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
---@param props StarcraftBlockOpponentProps
---@return Html
function StarcraftOpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, StarcraftOpponentDisplay.propTypes.BlockOpponent)
	local opponent = props.opponent
	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not StarcraftOpponent.isTbd(opponent))

	if opponent.type == 'team' then
		return StarcraftOpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			team = opponent.team,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' and opponent.extradata.hasRaceOrFlag then
		props.showRace = false
		return StarcraftOpponentDisplay.PlayerBlockOpponent(
			Table.merge(props, {showLink = showLink})
		)
	elseif opponent.type == 'literal' then
		return OpponentDisplay.BlockOpponent(props)
	else -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return StarcraftOpponentDisplay.PlayerBlockOpponent(
			Table.merge(props, {showLink = showLink})
		)
	end
end

---Displays a team as an inline element. The team is specified by a template.
---@param props {flip: boolean?, template: string, style: teamStyle?}
---@return string?
function StarcraftOpponentDisplay.InlineTeamContainer(props)
	return props.template == 'default'
		and OpponentDisplay.InlineTeam({flip = props.flip, template = props.template, teamStyle = props.style})
		or OpponentDisplay.InlineTeamContainer(props)
end

--[[
Displays a team as a block element. The width of the component is determined by
its layout context, and not of the team name. The team is specified by template.
]]
---@param props {flip: boolean?, overflow: OverflowModes?, showLink: boolean?, style: teamStyle?, template: string}
---@return Html
function StarcraftOpponentDisplay.BlockTeamContainer(props)
	return props.template == 'default'
		and OpponentDisplay.BlockTeam(Table.merge(props, {
			icon = mw.ext.TeamTemplate.teamicon('default'),
		}))
		or OpponentDisplay.BlockTeamContainer(props)
end

---Displays a player opponent (solo, duo, trio, or quad) as an inline element.
---@param props StarcraftInlineOpponentProps
---@return Html
function StarcraftOpponentDisplay.PlayerInlineOpponent(props)
	local showRace = props.showRace ~= false
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		local node = StarcraftPlayerDisplay.InlinePlayer({
			flip = props.flip,
			player = player,
			showFlag = props.showFlag,
			showLink = props.showLink,
			showRace = showRace and not opponent.isArchon,
		})
		return tostring(node)
	end)
	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	local playersNode = opponent.isArchon
		and '(' .. table.concat(playerTexts, ', ') .. ')'
		or table.concat(playerTexts, ' / ')

	local archonRaceNode
	if showRace and opponent.isArchon then
		archonRaceNode = Faction.Icon{faction = opponent.players[1].race}
	end

	return html.create('span')
		:node(not props.flip and archonRaceNode or nil)
		:node(playersNode)
		:node(props.flip and archonRaceNode or nil)
end

---Displays a player opponent (solo, duo, trio, or quad) as a block element.
---@param props StarcraftBlockOpponentProps
---@return Html
function StarcraftOpponentDisplay.PlayerBlockOpponent(props)
	local opponent = props.opponent
	local showRace = props.showRace ~= false

	--only apply note to first player, hence extract it here
	local note = Table.extract(props, 'note')

	local playerNodes = Array.map(opponent.players, function(player, playerIndex)
		return StarcraftPlayerDisplay.BlockPlayer(Table.merge(props, {
			player = player,
			team = player.team,
			note = playerIndex == 1 and note or nil,
			showRace = showRace and not opponent.isArchon and not opponent.isSpecialArchon,
		})):addClass(props.playerClass)
	end)

	if #opponent.players == 1 then
		return playerNodes[1]

	elseif showRace and opponent.isArchon then
		local raceIcon = Faction.Icon{size = 'large', faction = opponent.players[1].race}
		return StarcraftOpponentDisplay.BlockArchon({
			flip = props.flip,
			playerNodes = playerNodes,
			raceNode = html.create('div'):wikitext(raceIcon),
		})
		:addClass(props.showPlayerTeam and 'player-has-team' or nil)

	elseif showRace and opponent.isSpecialArchon then
		local archonsNode = html.create('div')
			:addClass('starcraft-special-archon-block-opponent')
			:addClass(props.showPlayerTeam and 'player-has-team' or nil)
		for archonIx = 1, #opponent.players / 2 do
			local primaryRace = opponent.players[2 * archonIx - 1].race
			local secondaryRace = opponent.players[2 * archonIx].race
			local primaryIcon = Faction.Icon{size = 'large', faction = primaryRace}
			local secondaryIcon
			if primaryRace ~= secondaryRace then
				secondaryIcon = html.create('div')
					:css('position', 'absolute')
					:css('right', '1px')
					:css('bottom', '1px')
					:node(StarcraftPlayerDisplay.Race(secondaryRace))
			end
			local raceNode = html.create('div')
				:css('position', 'relative')
				:node(primaryIcon)
				:node(secondaryIcon)

			local archonNode = StarcraftOpponentDisplay.BlockArchon({
				flip = props.flip,
				playerNodes = Array.sub(playerNodes, 2 * archonIx - 1, 2 * archonIx),
				raceNode = raceNode,
			})
			archonsNode:node(archonNode)
		end
		return archonsNode

	else
		local playersNode = html.create('div')
			:addClass(props.showPlayerTeam and 'player-has-team' or nil)
		for _, playerNode in ipairs(playerNodes) do
			playersNode:node(playerNode)
		end
		return playersNode
	end
end

StarcraftOpponentDisplay.propTypes.BlockArchon = {
	flip = 'boolean?',
	playerNodes = 'array',
	raceNode = 'any',
}

---Displays a block archon opponent
---@param props {flip: boolean?, playerNodes: Html[], raceNode: Html}
---@return Html
function StarcraftOpponentDisplay.BlockArchon(props)
	props.raceNode:addClass('starcraft-block-archon-race')

	local playersNode = html.create('div'):addClass('starcraft-block-archon-players')
	for _, node in ipairs(props.playerNodes) do
		playersNode:node(node)
	end

	return html.create('div'):addClass('starcraft-block-archon')
		:addClass(props.flip and 'flipped' or nil)
		:node(props.raceNode)
		:node(playersNode)
end

StarcraftOpponentDisplay.CheckMark = '<i class="fa fa-check forest-green-text" aria-hidden="true"></i>'

StarcraftOpponentDisplay.propTypes.BlockScore = {
	isWinner = 'boolean?',
	scoreText = 'any',
}

---Displays a score within the context of a block element.
---@param props {isWinner: boolean?, scoreText: string|number?}
---@return Html
function StarcraftOpponentDisplay.BlockScore(props)
	DisplayUtil.assertPropTypes(props, StarcraftOpponentDisplay.propTypes.BlockScore)

	local scoreText = props.scoreText
	if props.isWinner then
		scoreText = '<b>' .. scoreText .. '</b>'
	end

	return html.create('div')
		:wikitext(scoreText)
end

---Displays a score within the context of an inline element.
---@param opponent StarcraftStandardOpponent
---@return string
function StarcraftOpponentDisplay.InlineScore(opponent)
	if opponent.status == 'S' then
		local advantage = tonumber(opponent.extradata.advantage) or 0
		if advantage > 0 then
			local title = 'Advantage of ' .. advantage .. ' game' .. (advantage > 1 and 's' or '')
			return '<abbr title="' .. title .. '">' .. opponent.score .. '</abbr>'
		end
		local penalty = tonumber(opponent.extradata.penalty) or 0
		if penalty > 0 then
			local title = 'Penalty of ' .. penalty .. ' game' .. (penalty > 1 and 's' or '')
			return '<abbr title="' .. title .. '">' .. opponent.score .. '</abbr>'
		end
	end

	if Logic.readBool(opponent.extradata.noscore) then
		return (opponent.placement == 1 or opponent.advances)
			and StarcraftOpponentDisplay.CheckMark
			or ''
	end

	return OpponentDisplay.InlineScore(opponent)
end

return StarcraftOpponentDisplay

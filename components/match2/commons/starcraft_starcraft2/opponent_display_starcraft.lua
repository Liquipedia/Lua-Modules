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
local Opponent = require('Module:Opponent')
local StarcraftOpponent = require('Module:Opponent/Starcraft')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local StarcraftPlayerDisplay = Lua.import('Module:Player/Display/Starcraft', {requireDevIfEnabled = true})
local RaceIcon = Lua.requireIfExists('Module:RaceIcon') or {
	getBigIcon = function() end,
}

--[[
Display components for opponents used by the starcraft and starcraft 2 wikis
]]
local StarcraftOpponentDisplay = {propTypes = {}, types={}}

StarcraftOpponentDisplay.propTypes.InlineOpponent = {
	flip = 'boolean?',
	opponent = StarcraftOpponent.types.Opponent,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
}

--[[
Displays an opponent as an inline element. Useful for describing opponents in
prose.
]]
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
	elseif Opponent.typeIsParty(opponent.type) then
		return StarcraftOpponentDisplay.PartyAsInline(props)
	else
		return OpponentDisplay.InlineOpponent(props)
	end
end

StarcraftOpponentDisplay.propTypes.BlockOpponent = {
	flip = 'boolean?',
	opponent = StarcraftOpponent.types.Opponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	playerClass = 'string?',
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
}

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
function StarcraftOpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, StarcraftOpponentDisplay.propTypes.BlockOpponent)
	local opponent = props.opponent

	if opponent.type == 'team' then
		return StarcraftOpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = props.showLink,
			style = props.teamStyle,
			team = opponent.team,
			template = opponent.template or 'tbd',
		})
	elseif Opponent.typeIsParty(opponent.type) then
		return StarcraftOpponentDisplay.PartyAsBlock(props)
	elseif opponent.type == 'literal' and opponent.extradata.hasRaceOrFlag then
		props.showRace = false
		return StarcraftOpponentDisplay.PartyAsBlock(props)
	else
		return OpponentDisplay.BlockOpponent(props)
	end
end

function StarcraftOpponentDisplay.InlineTeamContainer(props)
	return props.template == 'default'
		and OpponentDisplay.InlineTeam(props)
		or OpponentDisplay.InlineTeamContainer(props)
end

function StarcraftOpponentDisplay.BlockTeamContainer(props)
	return props.template == 'default'
		and OpponentDisplay.BlockTeam(Table.merge(props, {
			icon = mw.ext.TeamTemplate.teamicon('default'),
		}))
		or OpponentDisplay.BlockTeamContainer(props)
end

StarcraftOpponentDisplay.propTypes.PartyAsInline = {
	flip = 'boolean?',
	opponent = StarcraftOpponent.types.Opponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showFlag = 'boolean?',
	showLink = 'boolean?',
}

--[[
Displays a party opponent (solo, duo, trio, or quad) as an inline element.
]]
function StarcraftOpponentDisplay.PartyAsInline(props)
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
		archonRaceNode = StarcraftPlayerDisplay.Race(opponent.players[1].race)
	end

	return mw.html.create('span')
		:node(not props.flip and archonRaceNode or nil)
		:node(playersNode)
		:node(props.flip and archonRaceNode or nil)
end

StarcraftOpponentDisplay.propTypes.PartyAsBlock = {
	flip = 'boolean?',
	opponent = StarcraftOpponent.types.Opponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showFlag = 'boolean?',
	showLink = 'boolean?',
}

--[[
Displays a party opponent (solo, duo, trio, or quad) as a block element.
]]
function StarcraftOpponentDisplay.PartyAsBlock(props)
	local opponent = props.opponent
	local showRace = props.showRace ~= false

	local playerNodes = Array.map(opponent.players, function(player)
		return StarcraftPlayerDisplay.BlockPlayer({
			flip = props.flip,
			overflow = props.overflow,
			player = player,
			showFlag = props.showFlag,
			showLink = props.showLink,
			showRace = showRace and not opponent.isArchon and not opponent.isSpecialArchon,
		})
			:addClass(props.playerClass)
	end)

	if #opponent.players == 1 then
		return playerNodes[1]

	elseif showRace and opponent.isArchon then
		local raceIcon = DisplayUtil.removeLinkFromWikiLink(
			RaceIcon.getBigIcon({opponent.players[1].race})
		)
		return StarcraftOpponentDisplay.BlockArchon({
			flip = props.flip,
			playerNodes = playerNodes,
			raceNode = mw.html.create('div'):wikitext(raceIcon),
		})

	elseif showRace and opponent.isSpecialArchon then
		local archonsNode = mw.html.create('div')
			:addClass('starcraft-special-archon-block-opponent')
		for archonIx = 1, #opponent.players / 2 do
			local primaryRace = opponent.players[2 * archonIx - 1].race
			local secondaryRace = opponent.players[2 * archonIx].race
			local primaryIcon = DisplayUtil.removeLinkFromWikiLink(
				RaceIcon.getBigIcon({primaryRace})
			)
			local secondaryIcon
			if primaryRace ~= secondaryRace then
				secondaryIcon = mw.html.create('div')
					:css('position', 'absolute')
					:css('right', '1px')
					:css('bottom', '1px')
					:node(StarcraftPlayerDisplay.Race(secondaryRace))
			end
			local raceNode = mw.html.create('div')
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
		local playersNode = mw.html.create('div')
		Array.extendWith(playersNode.nodes, playerNodes)
		return playersNode
	end
end

StarcraftOpponentDisplay.propTypes.BlockArchon = {
	flip = 'boolean?',
	playerNodes = 'array',
	raceNode = 'any',
}

function StarcraftOpponentDisplay.BlockArchon(props)
	props.raceNode:addClass('starcraft-block-archon-race')

	local playersNode = mw.html.create('div'):addClass('starcraft-block-archon-players')
	for _, node in ipairs(props.playerNodes) do
		playersNode:node(node)
	end

	return mw.html.create('div'):addClass('starcraft-block-archon')
		:addClass(props.flip and 'flipped' or nil)
		:node(props.raceNode)
		:node(playersNode)
end

StarcraftOpponentDisplay.CheckMark = '<i class="fa fa-check forest-green-text" aria-hidden="true"></i>'

StarcraftOpponentDisplay.propTypes.BlockScore = {
	isWinner = 'boolean?',
	scoreText = 'any',
}

--[[
Displays a score within the context of a block element.
]]
function StarcraftOpponentDisplay.BlockScore(props)
	DisplayUtil.assertPropTypes(props, StarcraftOpponentDisplay.propTypes.BlockScore)

	local scoreText = props.scoreText
	if props.isWinner then
		scoreText = '<b>' .. scoreText .. '</b>'
	end

	return mw.html.create('div')
		:wikitext(scoreText)
end

function StarcraftOpponentDisplay.InlineScore(opponent)
	if opponent.status == 'S' then
		local advantage = tonumber(opponent.extradata.advantage) or 0
		if advantage > 0 then
			local title = 'Advantage of ' .. advantage .. ' game' .. (advantage > 1 and 's' or '')
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

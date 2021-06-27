local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local OpponentDisplay = require('Module:OpponentDisplay')
local StarcraftMatchGroupUtil = require('Module:MatchGroup/Util/Starcraft')
local StarcraftPlayerDisplay = require('Module:Player/Display/Starcraft')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local RaceIcon = Lua.requireIfExists('Module:RaceIcon') or {
	getBigIcon = function() end,
}

local html = mw.html

--[[
Display components for opponents used by the starcraft and starcraft 2 wikis
]]
local StarcraftOpponentDisplay = {propTypes = {}, types={}}

StarcraftOpponentDisplay.propTypes.InlineOpponent = {
	flip = 'boolean?',
	opponent = StarcraftMatchGroupUtil.types.GameOpponent,
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
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	playerClass = 'string?',
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
	elseif opponent.type == 'literal' then
		return OpponentDisplay.BlockOpponent(props)
	else -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return StarcraftOpponentDisplay.PlayerBlockOpponent(props)
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

--[[
Displays a player opponent (solo, duo, trio, or quad) as an inline element.
]]
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
		archonRaceNode = StarcraftPlayerDisplay.Race(opponent.players[1].race)
	end

	return html.create('span')
		:node(not props.flip and archonRaceNode or nil)
		:node(playersNode)
		:node(props.flip and archonRaceNode or nil)
end

--[[
Displays a player opponent (solo, duo, trio, or quad) as a block element.
]]
function StarcraftOpponentDisplay.PlayerBlockOpponent(props)
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
			raceNode = html.create('div'):wikitext(raceIcon),
		})

	elseif showRace and opponent.isSpecialArchon then
		local archonsNode = html.create('div')
			:addClass('starcraft-special-archon-block-opponent')
		for archonIx = 1, #opponent.players / 2 do
			local primaryRace = opponent.players[2 * archonIx - 1].race
			local secondaryRace = opponent.players[2 * archonIx].race
			local primaryIcon = DisplayUtil.removeLinkFromWikiLink(
				RaceIcon.getBigIcon({primaryRace})
			)
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

return Class.export(StarcraftOpponentDisplay)

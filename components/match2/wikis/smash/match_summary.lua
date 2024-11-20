---
-- @Liquipedia
-- wiki=smash
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local PlayerDisplay = require('Module:Player/Display')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {
		width = CustomMatchSummary._determineWidth,
		teamStyle = 'bracket',
	})
end

---@param match MatchGroupUtilMatch
---@return string
function CustomMatchSummary._determineWidth(match)
	return CustomMatchSummary.isTeam(match) and '500px' or '400px'
end

---@param match MatchGroupUtilMatch
---@return boolean
function CustomMatchSummary.isTeam(match)
	if type(match.opponents[1]) ~= 'table' or type(match.opponents[2]) ~= 'table' then
		return false
	end
	return match.opponents[1].type == Opponent.team and match.opponents[2].type == Opponent.team
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	local games = Array.map(match.games, function(game)
		return CustomMatchSummary._createStandardGame(game, {
			opponents = match.opponents,
			game = match.game,
			soloMode = CustomMatchSummary.isTeam(match),
		})
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games
	)}
end

---@param game MatchGroupUtilGame
---@param matchOpponents table[]
---@param opponentIdx integer
---@return table[]
function CustomMatchSummary.fetchCharactersOfPlayers(game, matchOpponents, opponentIdx)
	return Array.map(game.opponents[opponentIdx].players, function (player, playerIndex)
		return Table.merge(matchOpponents[opponentIdx].players[playerIndex] or {}, player)
	end)
end

---@param game MatchGroupUtilGame
---@param props {game: string?, teamMode: boolean, opponents: table[]}
---@return Widget?
function CustomMatchSummary._createStandardGame(game, props)
	if not game or not game.participants then
		return
	end

	local function makeTeamSection(opponentIndex)
		local flipped = opponentIndex == 1
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, opponentIndex),
				props.game,
				flipped,
				props.teamMode
			),
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '0.75rem'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1), flipped = true},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game), css = {['flex-basis'] = '40%'}},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2)},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param players table[]
---@param game string?
---@param reverse boolean?
---@param displayPlayerNames boolean
---@return Html
function CustomMatchSummary._createCharacterDisplay(players, game, reverse, displayPlayerNames)
	local CharacterIcons = mw.loadData('Module:CharacterIcons/' .. (game or ''))
	local wrapper = mw.html.create('div')

	if Logic.isDeepEmpty(players) then
		return wrapper
	end

	local playerDisplays = Array.map(players, function (player)
		local characters = player.characters
		if Logic.isEmpty(characters) then
			return
		end
		local playerWrapper = mw.html.create('div')
			:css('display', 'flex')
			:css('flex-direction', reverse and 'row' or 'row-reverse')
			:css('position', 'relative')

		local charactersWrapper = mw.html.create('span')
		local characterDisplays = Array.map(characters, function(character, characterIndex)
			local characterDisplay = mw.html.create('div'):addClass('brkts-popup-body-element-thumbs')
			characterDisplay:wikitext(CharacterIcons[character.name])
			if character.status ~= 1 then
				characterDisplay:css('opacity', '0.3')
			end
			return characterDisplay
		end)
		local unknownCharactersCount = #Array.filter(characters, function (character) return character.status == -1 end)
		if unknownCharactersCount > 1 then
			local unknownCharactersWrapper = mw.html.create('span'):css('position', 'absolute')
			Array.forEach(Array.range(1, unknownCharactersCount), function()
				unknownCharactersWrapper:wikitext(CharacterIcons.Unknown)
			end)
			playerWrapper:node(unknownCharactersWrapper)
		end

		Array.forEach(characterDisplays, FnUtil.curry(charactersWrapper.node, charactersWrapper))
		playerWrapper:node(charactersWrapper)

		if displayPlayerNames then
			playerWrapper:node('&nbsp;')
			playerWrapper:node(PlayerDisplay.BlockPlayer{player = player, flip = not reverse})
		end

		return playerWrapper
	end)

	Array.forEach(playerDisplays, FnUtil.curry(wrapper.node, wrapper))

	return wrapper
end

return CustomMatchSummary

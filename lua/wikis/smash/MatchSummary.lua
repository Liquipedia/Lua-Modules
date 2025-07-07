---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local PlayerDisplay = Lua.import('Module:Player/Display')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {
		width = '350px',
		teamStyle = 'bracket',
	})
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
			teamMode = CustomMatchSummary.isTeam(match),
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
	if not game or Logic.isDeepEmpty(game.opponents) then
		return
	end

	local function makeTeamSection(opponentIndex)
		local flipped = opponentIndex == 2
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
			MatchSummaryWidgets.GameCenter{children = game.map, css = {['flex-basis'] = '100px', ['text-align'] = 'center'}},
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
	local CharacterIcons = Lua.import('Module:CharacterIcons/' .. (game or ''), {loadData = true})
	local wrapper = mw.html.create('div'):css{
		display = 'flex',
		['align-items'] = 'flex-start',
		['flex-direction'] = 'column',
	}

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
			:css('flex-direction', 'column')
			:css('width', '100%')
			:css('align-items', reverse and 'flex-start' or 'flex-end')

		if displayPlayerNames then
			playerWrapper:node(PlayerDisplay.BlockPlayer{player = player, flip = not reverse})
		end

		local charactersWrapper = mw.html.create('span')
			:css('display', 'flex')
			:css('flex-direction', reverse and 'row-reverse' or 'row')
			:css('position', 'relative')
		local characterDisplays = Array.map(characters, function(character, characterIndex)
			local characterDisplay = mw.html.create('span')
				:addClass('brkts-popup-body-element-thumbs')
				:css('opacity', character.status ~= 1 and '0.3' or nil)
			characterDisplay:wikitext(CharacterIcons[character.name])
			return characterDisplay
		end)
		local unknownCharactersCount = #Array.filter(characters, function (character) return character.status == -1 end)
		if unknownCharactersCount > 1 then
			local unknownCharactersWrapper = mw.html.create('span')
				:css('position', 'absolute')
				:css('width', '100%')
				:css('display', 'flex')
				:css('flex-direction', reverse and 'row-reverse' or 'row')
			Array.forEach(Array.range(1, unknownCharactersCount), function()
				unknownCharactersWrapper:wikitext(CharacterIcons.Unknown)
			end)
			charactersWrapper:node(unknownCharactersWrapper)
		end

		Array.forEach(characterDisplays, FnUtil.curry(charactersWrapper.node, charactersWrapper))
		playerWrapper:node(charactersWrapper)



		return playerWrapper
	end)

	Array.forEach(playerDisplays, FnUtil.curry(wrapper.node, wrapper))

	return wrapper
end

return CustomMatchSummary

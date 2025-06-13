---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local MapTypeIcon = require('Module:MapType')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local WeaponIcon = require('Module:WeaponIcon')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NON_BREAKING_SPACE = '&nbsp;'

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '490px', teamStyle = 'bracket'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	local weaponsData = Array.map(game.opponents, function(opponent)
		return Array.map(opponent.players, Operator.property('weapon'))
	end)

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '90%', padding = '4px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._opponentWeaponsDisplay{
				data = weaponsData[1],
				flip = false,
				game = game.game
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			CustomMatchSummary._gameScore(game, 1),
			MatchSummaryWidgets.GameCenter{children = CustomMatchSummary._getMapDisplay(game), css = {['flex-grow'] = 1}},
			CustomMatchSummary._gameScore(game, 2),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._opponentWeaponsDisplay{
				data = weaponsData[2],
				flip = true,
				game = game.game
			},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@return string
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'

	if String.isNotEmpty(game.extradata.maptype) then
		mapDisplay = MapTypeIcon.display(game.extradata.maptype) .. NON_BREAKING_SPACE .. mapDisplay
	end

	return mapDisplay
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local opponentCopy = Table.deepCopy(game.opponents[opponentIndex])
	if opponentCopy.score and game.mode == 'Turf War' then
		opponentCopy.score = opponentCopy.score .. '%'
	end
	local scoreDisplay = DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
	return mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('min-width', '24px')
		:node(mw.html.create('div')
			:css('margin', 'auto')
			:wikitext(scoreDisplay)
		)
end

---@param props {data: string[], flip: boolean, game: string}
---@return Html
function CustomMatchSummary._opponentWeaponsDisplay(props)
	local flip = props.flip

	local displayElements = Array.map(props.data, function(weapon)
		return mw.html.create('div')
			:addClass('brkts-champion-icon')
			:node(WeaponIcon._getImage{
				weapon = weapon,
				game = props.game,
				class = 'brkts-champion-icon',
			})
	end)

	if flip then
		displayElements = Array.reverse(displayElements)
	end

	local display = mw.html.create('div')
		:addClass('brkts-popup-body-element-thumbs')
		:addClass(flip and 'brkts-popup-body-element-thumbs-right' or nil)

	for _, item in ipairs(displayElements) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary

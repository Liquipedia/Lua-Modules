---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapTypeIcon = require('Module:MapType')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local WeaponIcon = require('Module:WeaponIcon')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local NON_BREAKING_SPACE = '&nbsp;'

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '490px', teamStyle = 'bracket'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	local row = MatchSummary.Row()

	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummaryWidgets.Break{})
	end

	local weaponsData = Array.map(game.opponents, function(opponent)
		return Array.map(opponent.players, Operator.property('weapon'))
	end)

	row:addClass('brkts-popup-body-game')
		:css('font-size', '90%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentWeaponsDisplay{
		data = weaponsData[1],
		flip = false,
		game = game.game
	})
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(CustomMatchSummary._gameScore(game, 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('min-width', '156px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:node(mw.html.create('div')
			:css('margin', 'auto')
			:wikitext(CustomMatchSummary._getMapDisplay(game))
		)
	)
	row:addElement(CustomMatchSummary._gameScore(game, 2))
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})
	row:addElement(CustomMatchSummary._opponentWeaponsDisplay{
		data = weaponsData[2],
		flip = true,
		game = game.game
	})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment:wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	return row:create()
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
	local score = game.scores[opponentIndex] --[[@as number|string?]]
	if score and game.mode == 'Turf War' then
		score = score .. '%'
	end
	local scoreDisplay = DisplayHelper.MapScore(score, opponentIndex, game.resultType, game.walkover, game.winner)
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

---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Operator = Lua.import('Module:Operator')
local WeaponIcon = Lua.import('Module:WeaponIcon')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local WidgetUtil = Lua.import('Module:Widget/Util')


local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px', teamStyle = 'bracket'})
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	local weaponsData = Array.map(game.opponents, function(opponent)
		return Array.map(opponent.players, Operator.property('weapon'))
	end)
	if not game.map then
		return
	end

	local function makeTeamSection(opponentIndex)
		local opponent = game.opponents[opponentIndex] or {}
		local weaponsData = Array.map(opponent.players or {}, Operator.property('weapon'))

		local score = opponent.score
		if score and game.mode == 'turf war' then
			score = score .. '%'
		end
		local scoreDisplay = DisplayHelper.MapScore({score = score}, game.status)

		return {
			CustomMatchSummary._createWeaponsDisplay{
				data = weaponsData,
				flip = (opponentIndex == 2),
				game = game.game
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			HtmlWidgets.Div{
				css = {['min-width'] = '24px', ['text-align'] = 'center'},
				children = scoreDisplay,
			}
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.MapAndMode(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param props {data: string[], flip: boolean, game: string}
---@return Widget
function CustomMatchSummary._createWeaponsDisplay(props)
	local weaponIcons = Array.map(props.data, function(weapon)
		return HtmlWidgets.Div{
			classes = {'brkts-champion-icon'},
			children = WeaponIcon.Icon{
				weapon = weapon,
				game = props.game,
				class = 'brkts-champion-icon',
			}
		}
	end)

	if props.flip then
		weaponIcons = Array.reverse(weaponIcons)
	end

	local classes = {'brkts-popup-body-element-thumbs'}
	if props.flip then
		table.insert(classes, 'brkts-popup-body-element-thumbs-right')
	end

	return HtmlWidgets.Div{
		classes = classes,
		children = weaponIcons
	}
end

return CustomMatchSummary

---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/GameDetails
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {game: FFAMatchGroupUtilGame}
---@return VNode
local function MatchSummaryFfaGameDetails(props)
	local game = props.game
	assert(game, 'No game provided')

	local casters = game.extradata.casters and DisplayHelper.createCastersDisplay(game.extradata.casters) or nil

	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = WidgetUtil.collect(
		{
			icon = CountdownIcon{game = game},
			content = GameCountdown{game = game},
		},
		game.map and {
			icon = IconWidget{iconName = 'map'},
			content = Html.Span{children = Page.makeInternalLink(game.mapDisplayName or game.map, game.map)},
		} or nil,
		Logic.isNotEmpty(casters) and {
			icon = IconWidget{
				iconName = 'casters',
				additionalClasses = {'fa-fw'},
				hover = 'Caster' .. (#casters > 1 and 's' or '')
			},
			content = Html.Span{children = Array.interleave(casters, ', ')},
		} or nil,
		game.comment and {
			icon = IconWidget{iconName = 'comment'},
			content = Html.Span{children = game.comment},
		} or nil
	)}
end

return Component.component(MatchSummaryFfaGameDetails)

---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')

---@param props {matchId: string, games: FFAMatchGroupUtilGame[]}
---@return VNode
local function MatchSummaryFfaHeader(props)
	assert(props.matchId, 'No matchId provided')
	assert(type(props.games) == 'table', 'No games provided')

	local function headerItem(title, icon, idx)
		return Html.Li{
			classes = {'panel-tabs__list-item'},
			attributes = {
				['data-js-battle-royale'] = 'panel-tab',
				['data-js-battle-royale-content-target-id'] = props.matchId .. 'panel' .. idx,
				role = 'tab',
				tabindex = 0,
			},
			children = {
				icon,
				Html.H4{
					classes = {'panel-tabs__title'},
					children = title,
				},
			},
		}
	end

	local standingsIcon = IconWidget{iconName = 'standings', additionalClasses = {'panel-tabs__list-icon'}}

	return Html.Div{
		classes = {'panel-tabs'},
		attributes = {
			role = 'tabpanel',
		},
		children = Html.Ul{
			classes = {'panel-tabs__list'},
			attributes = {
				role = 'tablist',
			},
			children = WidgetUtil.collect(
				headerItem('Overall standings', standingsIcon, 0),
				Array.map(props.games, function (game, idx)
					return headerItem('Game '.. idx, CountdownIcon{game = game, additionalClasses = {'panel-tabs__list-icon'}}, idx)
				end)
			)
		},
	}
end

return Component.component(MatchSummaryFfaHeader)

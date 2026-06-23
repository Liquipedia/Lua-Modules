---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/Sublist
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local TournamentLabel = Lua.import('Module:Widget/Tournament/Label')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class TournamentsTickerSublistProps
---@field title string?
---@field tournaments StandardTournament[]
---@field displayGameIcons boolean?
---@field createItem (fun(tournament: StandardTournament): Renderable)?
---@field fallback Widget?

---@param props TournamentsTickerSublistProps
---@return VNode?
local function TournamentsTickerSublist(props)
	if not props.tournaments then
		return
	end

	local createItem = props.createItem or function(tournament)
		return TournamentLabel{
			tournament = tournament,
			displayGameIcon = props.displayGameIcons,
		}
	end

	---@param tournament StandardTournament
	---@param child Renderable
	---@return Renderable
	local createFilterWrapper = function(tournament, child)
		return Array.reduce(FilterConfig.categories, function(prev, filterCategory)
			local itemIsValid = filterCategory.itemIsValid or function(item) return true end
			local itemToPropertyValues = filterCategory.itemToPropertyValues or function(item) return item end
			local value = tournament[filterCategory.property]
			local filterValue = itemIsValid(value) and value or filterCategory.defaultItem
			return Html.Div{
				attributes = {
					['data-filter-group'] = 'filterbuttons-' .. filterCategory.name,
					['data-filter-category'] = itemToPropertyValues(filterValue),
					['data-curated'] = tournament.featured and '' or nil,
				},
				children = prev,
			}
		end, child)
	end

	local list = Html.Ul{
		classes = {'tournaments-list-type-list'},
		children = Array.map(props.tournaments, function(tournament)
			return Html.Li{children = createFilterWrapper(tournament, createItem(tournament))}
		end),
	}

	return Html.Div{
		attributes = {
			['data-filter-hideable-group'] = '',
			['data-filter-effect'] = 'fade',
		},
		children = WidgetUtil.collect(
			props.title and Html.Span{
				classes = {'tournaments-list-heading'},
				children = props.title,
			} or nil,
			list,
			props.fallback
		),
	}
end

return Component.component(TournamentsTickerSublist)

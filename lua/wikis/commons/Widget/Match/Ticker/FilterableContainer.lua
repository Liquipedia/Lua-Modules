---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/FilterableContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FeatureFlag = Lua.import('Module:FeatureFlag')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local CarouselButton = Lua.import('Module:Widget/Basic/Carousel/Button')
local Component = Lua.import('Module:Widget/Component')
local ContentSwitchPill = Lua.import('Module:Widget/ContentSwitch/Pill')
local Html = Lua.import('Module:Widget/Html')
local Panel = Lua.import('Module:Widget/Panel')
local Switch = Lua.import('Module:Widget/Switch')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@alias MatchTickerMatchQueryType 'upcoming'|'recent'

local defaultProps = {
	limit = 10,
	module = 'MatchTicker/Custom',
	fn = 'mainPage',
}

---@param props {module: string?, fn: string?, limit: integer?, displayGameIcons: boolean?}
---@return VNode
local function MatchTickerContainer(props)
	local function filterName(filter)
		return 'filterbuttons-' .. filter
	end

	local filters = Array.map(FilterConfig.categories, Operator.property('name')) or {}
	local filterText = table.concat(Array.map(filters, filterName), ',')

	local defaultFilterParams = Table.map(FilterConfig.categories, function (_, category)
		return filterName(category.name), table.concat(category.defaultItems or {}, ',')
	end)

	local matchTickerArgs = {
		limit = props.limit,
		displayGameIcons = props.displayGameIcons,
		variant = 'carousel',
		showInfoForEmptyResults = true,
	}

	local devFlag = FeatureFlag.get('dev')

	---@param type MatchTickerMatchQueryType
	---@return string
	local function buildTemplateExpansionString(type)
		return String.interpolate(
			'#invoke:Lua|invoke|module=${module}|fn=${fn}${args}',
			{
				module = props.module,
				fn = props.fn,
				args = table.concat(Array.extractValues(Table.map(
					Table.merge(matchTickerArgs, {type=type, dev=devFlag}),
					function (key, value)
						return key, String.interpolate('|${key}=${value}', {key = key, value = tostring(value)})
					end
				)), '')
			}
		)
	end

	---@param type MatchTickerMatchQueryType
	---@return Renderable
	local function callTemplate(type)
		local ticker = Lua.import('Module:' .. props.module)
		return ticker[props.fn](
			Table.merge(
				{type=type},
				matchTickerArgs,
				defaultFilterParams
			)
		)
	end

	---@param tabIndex integer
	---@param type MatchTickerMatchQueryType
	---@param attributes table<string, string>?
	---@return VNode
	local function buildTabContent(tabIndex, type, attributes)
		return Html.Div{
			attributes = Table.merge({['data-toggle-area-content'] = tabIndex}, attributes),
			children = Html.Div{
				attributes = {
					['data-filter-expansion-template'] = buildTemplateExpansionString(type),
					['data-filter-groups'] = filterText,
				},
				children = callTemplate(type),
			},
		}
	end

	local switchPill = ContentSwitchPill{
		switchGroup = 'matchFiler',
		defaultActive = 1,
		variant = 'generic',
		size = 'extrasmall',
		storeValue = true,
		tabs = {
			{label = 'Upcoming', value = 'upcoming'},
			{label = 'Completed', value = 'completed'},
		},
	}
	local countdownSwitch = Html.Div{
		attributes = {['data-toggle-area-content'] = 1},
		children = Switch{
			label = 'Show countdown',
			switchGroup = 'countdown',
			storeValue = true,
			defaultActive = true,
		},
	}

	return Panel{
		classes = {
			'match-ticker-filterable-container',
			'carousel',
			'toggle-area',
			'toggle-area-1',
		},
		panelAttributes = {
			['data-toggle-area'] = 1,
			-- Header controls stay visible and are only greyed out at either end of the list
			['data-carousel-controls'] = 'disable',
		},
		heading = {
			Html.Div{
				classes = {'match-ticker-filterable-container__header-start'},
				children = {
					Html.Span{
						classes = {'match-ticker-filterable-container__title'},
						children = 'Matches',
					},
					Html.Div{
						classes = {'match-ticker-filterable-container__navigation', 'mobile-hide'},
						children = {
							switchPill,
							countdownSwitch,
						}
					},
				},
			},
			Html.Div{
				classes = {
					'match-ticker-filterable-container__header-end',
					'mobile-hide',
				},
				children = {
					CarouselButton{direction = 'left'},
					CarouselButton{direction = 'right'},
				},
			},
		},
		children = {
			-- On small screens the tab pill and countdown switch move out of the header into their own strip
			Html.Div{
				classes = {
					'match-ticker-filterable-container__navigation',
					'match-ticker-filterable-container__navigation--body',
					'mobile-only',
				},
				children = {
					switchPill,
					countdownSwitch,
				}
			},
			-- Only the upcoming matches are affected by the countdown switch
			buildTabContent(1, 'upcoming', {['data-switch-group-container'] = 'countdown'}),
			buildTabContent(2, 'recent'),
		},
	}
end

return Component.component(MatchTickerContainer, defaultProps)

---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Ticker/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class MatchTickerContainer: Widget
---@operator call(table): MatchTickerContainer
local MatchTickerContainer = Class.new(Widget)
MatchTickerContainer.defaultProps = {
	matchTicker = {
		module = 'MatchTicker/Custom',
		fn = 'newMainPage',
		args = {
			upcomingLimit = 10,
			ongoingLimit = 10,
			recentLimit = 10,
		}
	},
}

---@return Widget
function MatchTickerContainer:render()
	local function filterName(filter)
		return 'filterbuttons-' .. filter
	end

	local filters = Array.map(FilterConfig.categories, Operator.property('name')) or {}
	local filterText = table.concat(Array.map(filters, filterName), ',')

	local defaultFilterParams = Array.reduce(FilterConfig.categories, function (aggregate, category)
		return Table.merge(aggregate, {
			[filterName(category.name)] = table.concat(category.defaultItems, ',')
		})
	end, {})

	---@param type 'upcoming' | 'recent'
	local function buildTemplateExpansionString(type)
		local config = self.defaultProps.matchTicker

		return String.interpolate(
			'#invoke:Lua|invoke|module=${module}|fn=${fn}${args}',
			{
				module = config.module,
				fn = config.fn,
				args = table.concat(Array.map(
					Table.entries(Table.merge(config.args, {type=type})),
					function (entry)
						return String.interpolate('|${1}=${2}', entry)
					end
				), '')
			}
		)
	end

	---@param type 'upcoming' | 'recent'
	local function callTemplate(type)
		local config = self.defaultProps.matchTicker
		local ticker = require(config.module)
		return ticker[config.fn](
			Table.merge(
				config.args,
				{type = type},
				defaultFilterParams
			)
		)
	end

	return HtmlWidgets.Div{
		classes = {'toggle-area', 'toggle-area-1'},
		attributes = {['data-toggle-area'] = '1'},
		children = {
			HtmlWidgets.Div{
				classes = {'match-section-header'},
				children = {
					HtmlWidgets.Div{
						classes = {'switch-pill-container'},
						children = {
							HtmlWidgets.Div{
								classes = {'switch-pill'},
								attributes = {
									['data-switch-group'] = 'matchFiler',
									['data-store-value'] = 'true',
								},
								children = {
									HtmlWidgets.Div{
										classes = {'switch-pill-option', 'switch-pill-active', 'toggle-area-button'},
										attributes = {
											['data-toggle-area-btn'] = '1',
											['data-switch-value'] = 'upcoming',
										},
										children = 'Upcoming',
									},
									HtmlWidgets.Div{
										classes = {'switch-pill-option', 'toggle-area-button'},
										attributes = {
											['data-toggle-area-btn'] = '2',
											['data-switch-value'] = 'completed',
										},
										children = 'Completed',
									},
								},
							},
						},
					},
				},
			},
			HtmlWidgets.Div{
				classes = {'switch-toggle-container'},
				css = {margin = '1rem 0'},
				children = {
					HtmlWidgets.Div{
						classes = {'switch-toggle'},
						attributes = {
							['data-switch-group'] = 'countdown',
							['data-store-value'] = 'true',
						},
						children = {
							HtmlWidgets.Div{classes = {'switch-toggle-slider'}},
						},
					},
					HtmlWidgets.Div{children = 'Show Countdown'},
				},
			},
			HtmlWidgets.Div{
				attributes = {
					['data-toggle-area-content'] = '1',
					['data-filter-expansion-template'] = buildTemplateExpansionString('upcoming'),
					['data-filter-groups'] = filterText,
				},
				children = callTemplate('upcoming'),
			},
			HtmlWidgets.Div{
				attributes = {
					['data-toggle-area-content'] = '2',
					['data-filter-expansion-template'] = buildTemplateExpansionString('recent'),
					['data-filter-groups'] = filterText,
				},
				children = callTemplate('upcoming'),
			},
		},
	}
end

return MatchTickerContainer

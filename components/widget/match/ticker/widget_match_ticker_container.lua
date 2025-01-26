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
local Template = require('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class MatchTickerContainer: Widget
---@operator call(table): MatchTickerContainer
local MatchTickerContainer = Class.new(Widget)
MatchTickerContainer.defaultProps = {
	upcomingTemplate = 'MainPageMatches/Upcoming',
	completedTemplate = 'MainPageMatches/Completed',
}

---@return Widget
function MatchTickerContainer:render()
	local upcomingTemplate = self.props.upcomingTemplate
	local completedTemplate = self.props.completedTemplate

	local filters = Array.map(FilterConfig.categories, Operator.property('property')) or {}
	local filterText = table.concat(Array.map(filters, function(filter)
		return 'filterbuttons-' .. string.lower(filter)
	end), ',')

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
					['data-filter-expansion-template'] = upcomingTemplate,
					['data-filter-groups'] = filterText,
				},
				children = Template.safeExpand(mw.getCurrentFrame(), upcomingTemplate),
			},
			HtmlWidgets.Div{
				attributes = {
					['data-toggle-area-content'] = '2',
					['data-filter-expansion-template'] = completedTemplate,
					['data-filter-groups'] = filterText,
				},
				children = Template.safeExpand(mw.getCurrentFrame(), completedTemplate),
			},
		},
	}
end

return MatchTickerContainer

---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FeatureFlag = Lua.import('Module:FeatureFlag')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Switch = Lua.import('Module:Widget/Switch')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

---@class MatchTickerContainer: Widget
---@operator call(table): MatchTickerContainer
local MatchTickerContainer = Class.new(Widget)
MatchTickerContainer.defaultProps = {
	limit = 10,
	module = 'MatchTicker/Custom',
	fn = 'newMainPage',
}

---@return Widget
function MatchTickerContainer:render()
	local function filterName(filter)
		return 'filterbuttons-' .. filter
	end

	local filters = Array.map(FilterConfig.categories, Operator.property('name')) or {}
	local filterText = table.concat(Array.map(filters, filterName), ',')

	local defaultFilterParams = Table.map(FilterConfig.categories, function (_, category)
		return filterName(category.name), table.concat(category.defaultItems or {}, ',')
	end)

	local matchTickerArgs = {
		limit = self.props.limit,
		displayGameIcons = self.props.displayGameIcons
	}

	local devFlag = FeatureFlag.get('dev')

	---@param type 'upcoming' | 'recent'
	local function buildTemplateExpansionString(type)
		return String.interpolate(
			'#invoke:Lua|invoke|module=${module}|fn=${fn}${args}',
			{
				module = self.defaultProps.module,
				fn = self.defaultProps.fn,
				args = table.concat(Array.extractValues(Table.map(
					Table.merge(matchTickerArgs, {type=type, dev=devFlag}),
					function (key, value)
						return key, String.interpolate('|${key}=${value}', {key = key, value = tostring(value)})
					end
				)), '')
			}
		)
	end

	---@param type 'upcoming' |'recent'
	local function callTemplate(type)
		local ticker = Lua.import('Module:' .. self.defaultProps.module)
		return ticker[self.defaultProps.fn](
			Table.merge(
				{type=type},
				matchTickerArgs,
				defaultFilterParams
			)
		)
	end

	return HtmlWidgets.Div{
		classes = {'match-section-header'},
		children = {
			ContentSwitch{
				tabs = {
					{
						label = 'Upcoming',
						value = 'upcoming',
						content = {
							Switch{
								label = 'Show Countdown',
								switchGroup = 'countdown',
								storeValue = true,
								defaultActive = true,
								css = {margin = '1rem 0', ['justify-content'] = 'center'},
								content = HtmlWidgets.Div{
									attributes = {
										['data-filter-expansion-template'] = buildTemplateExpansionString('upcoming'),
										['data-filter-groups'] = filterText,
									},
									children = callTemplate('upcoming'),
								}
							}
						}
					},
					{
						label = 'Completed',
						value = 'completed',
						content = {
							HtmlWidgets.Div{
								attributes = {
									['data-filter-expansion-template'] = buildTemplateExpansionString('recent'),
									['data-filter-groups'] = filterText,
								},
								children = callTemplate('recent'),
							}
						}
					}
				},
				switchGroup = 'matchFiler',
				defaultActive = 1,
			}
		},
	}
end

return MatchTickerContainer

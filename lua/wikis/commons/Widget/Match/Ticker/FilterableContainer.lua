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

local Component = Lua.import('Module:Widget/Component')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')
local Html = Lua.import('Module:Widget/Html')
local Switch = Lua.import('Module:Widget/Switch')
local FilterConfig = Lua.import('Module:FilterButtons/Config')

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
		displayGameIcons = props.displayGameIcons
	}

	local devFlag = FeatureFlag.get('dev')

	---@param type 'upcoming' | 'recent'
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

	---@param type 'upcoming' |'recent'
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

	return Html.Div{
		classes = {'match-section-header'},
		css = {['padding-top'] = '0.75rem'},
		children = {
			ContentSwitch{
				css = {margin = '0 0.75rem 0.75rem'},
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
								content = Html.Div{
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
							Html.Div{
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

return Component.component(MatchTickerContainer, defaultProps)

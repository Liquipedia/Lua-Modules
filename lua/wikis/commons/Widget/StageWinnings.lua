---
-- @Liquipedia
-- page=Module:Widget/StageWinnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[to replace:
- Module:StageWinnings hok, ml
- Module:GroupStageWinnings sc, sc2, aoe, geo
]]

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local StageWinningsCalculation = Lua.import('Module:StageWinningsCalculation')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Widget = Lua.import('Module:Widget')
local Widgets = Lua.import('Module:Widget/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BASE_CURRENCY = 'USD'
local EXCHANGE_SUMMARY_PRECISION = 5

---@class StageWinningProps
---@field tournaments string
---@field ids string?
---@field sdate string|number|osdate|osdateparam?
---@field edate string|number|osdate|osdateparam?
---@field prizeMode 'matchWins'|'gameWins'|'scores'
---@field valueStart number?
---@field valuePerWin number?
---@field n-m number? # n amd m integers
---@field localcurrency string?
---@field width integer?
---@field cutafter integer?
---@field title string?
---@field precision integer?
---@field autoexchange boolean
---@field exchangeinfo boolean
---@field showMatchWL boolean
---@field showGameWL boolean
---@field showScore boolean

---@class StageWinnings: Widget
---@operator call(table): StageWinnings
---@field props StageWinningProps
local StageWinnings = Class.new(Widget)
StageWinnings.defaultProps = {
	tournaments = mw.title.getCurrentTitle().text,
	delimiter = ',',
	autoexchange = true,
	prizeMode = 'matchWins'
}

---@return Widget?
function StageWinnings:render()
	local props = self.props

	local startDate = DateExt.readTimestamp(props.sdate)
	local endDate = DateExt.readTimestamp(props.edate)

	local valueByScore = Table.filterByKey(props, function(key)
		return key:match('^%d+%-%d+$') ~= nil
	end)
	valueByScore = Table.map(valueByScore, function(key, value)
		return key, tonumber(value)
	end)

	assert(props.prizeMode == 'matchWins' or props.prizeMode == 'gameWins' or props.prizeMode == 'scores',
		'Invalid prizeMode input')
	assert(props.prizeMode ~= 'scores' or Logic.isNotEmpty(valueByScore),
		'No values per scores defined')

	local opponentList = StageWinningsCalculation.run{
		ids = props.ids,
		tournaments = props.tournaments,
		startDate = startDate,
		endDate = endDate,
		mode = props.prizeMode,
		valueByScore = valueByScore,
		startValue = tonumber(props.valueStart) or 0,
		valuePerWin = tonumber(props.valuePerWin) or 0,
	}

	if Logic.isNotEmpty(props.localcurrency) then
		Currency.display(props.localcurrency, nil, {setVariables = true})
		self.exchangeSettings = {
			exchangeDate = endDate or DateExt.getContextualDateOrNow(),
			localCurrency = props.localcurrency,
			precision = tonumber(props.precision) or 0,
			rate = Currency.getExchangeRate{
				currency = props.localcurrency,
				currencyRate = Variables.varDefault('exchangerate_' .. props.localcurrency:upper()),
				date = DateExt.toYmdInUtc(endDate or DateExt.getContextualDateOrNow()),
				setVariables = false
			},
			autoExchange = Logic.nilOr(Logic.readBoolOrNil(props.autoexchange), true),
			exchangeInfo = Logic.nilOr(Logic.readBoolOrNil(props.exchangeinfo), false),
		}
	end

	local tbl = Widgets.DataTable{
		classes = {'prizepooltable', 'collapsed'},
		tableCss = {
			['text-align'] = 'center',
			['margin-top'] = 0,
			['margin-bottom'] = 0,
			width = 'auto',
		},
		tableAttributes = {
			['data-cutafter'] = (tonumber(props.cutafter) or 5) + 1, -- +1 due to 2nd headerRow
			['data-opentext'] = 'Show remaining participants',
			['data-closetext'] = 'Hide remaining participants',
		},
		children = WidgetUtil.collect(
			-- first header
			Widgets.Tr{
				children = {
					Widgets.Th{
						attributes = {colspan = '100%'},
						children = {props.title or 'Group Stage Winnings'},
					},
				},
			},
			-- second header
			self:_headerRow(),
			-- rows
			Array.map(opponentList, FnUtil.curry(self._row, self))
		)
	}

	--todo: add exchange info if enabled
	return tbl
end

---@return Widget
function StageWinnings:_headerRow()
	local props = self.props
	return Widgets.Tr{
		children = WidgetUtil.collect(
			Widgets.Th{
				css = {width = 'auto'},
				children = {'Participants'},
			},
			(Logic.readBool(props.showMatchWL) or props.prizeMode == 'matchWins') and Widgets.Th{
				css = {width = 'auto'},
				children = {'Matches'},
			} or nil,
			(Logic.readBool(props.showGameWL) or props.prizeMode == 'gameWins') and Widgets.Th{
				css = {width = 'auto'},
				children = {'Games'},
			} or nil,
			Logic.readBool(props.showScore) and Widgets.Th{
				css = {width = 'auto'},
				children = {'Score Details'},
			} or nil,
			Logic.isNotEmpty(props.localcurrency) and Widgets.Th{
				css = {width = 'auto'},
				children = {Currency.display(props.localcurrency)},
			} or nil,
			(Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency)) and Widgets.Th{
				css = {width = 'auto'},
				children = {Currency.display(BASE_CURRENCY)},
			} or nil
		),
	}
end

---@param opponent {opponent: standardOpponent, matchWins: integer, matchLosses: integer, gameWins: integer,
---gameLosses: integer, winnings: number, scoreDetails: table<string, integer>}
---@return Widget
function StageWinnings:_row(opponent)
	return Widgets.Tr{
		children = {
			Widgets.Td{
				children = {},
			},
			Widgets.Td{
				children = {},
			},
			Widgets.Td{
				children = {},
			},
			Widgets.Td{
				children = {},
			},
			Widgets.Td{
				children = {},
			},
			Widgets.Td{
				children = {},
			},
			Widgets.Td{
				children = {},
			},
		},
	}
end


return StageWinnings
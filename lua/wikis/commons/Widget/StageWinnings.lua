---
-- @Liquipedia
-- page=Module:Widget/StageWinnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local StageWinningsCalculation = Lua.import('Module:StageWinningsCalculation')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BASE_CURRENCY = 'USD'

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
---@field legendTitle string?
---@field showLegend boolean
---@field autoexchange boolean
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
	prizeMode = 'matchWins',
	title = 'Group Stage Winnings',
}

---@return Widget?
function StageWinnings:render()
	local props = self.props

	local startDate = DateExt.readTimestamp(props.sdate)
	local endDate = DateExt.readTimestamp(props.edate)

	local valueByScore = Table.filterByKey(props, function(key)
		if key:match('^%d+%-%d+$') ~= nil then
			return true
		end
		local keyParts = Array.parseCommaSeparatedString(key, '-')
		return #keyParts == 2 and
			Array.all(keyParts, function(keyPart) return Table.includes(MatchGroupInputUtil.STATUS, keyPart) end)
	end)
	valueByScore = Table.map(valueByScore, function(key, value)
		return key, tonumber(value)
	end)

	assert(props.prizeMode == 'matchWins' or props.prizeMode == 'gameWins' or props.prizeMode == 'scores',
		'Invalid prizeMode input')
	assert(props.prizeMode ~= 'scores' or Logic.isNotEmpty(valueByScore),
		'No values per scores defined')

	local opponentList = StageWinningsCalculation.run{
		matchGroupsSpecProps = Table.filterByKey(props, function(key)
			return String.startsWith(key, 'tournament') or String.startsWith(key, 'matchGroupId')
		end) --[[@as table<string, string>]],
		startDate = startDate,
		endDate = endDate,
		mode = props.prizeMode,
		valueByScore = valueByScore,
		startValue = tonumber(props.valueStart) or 0,
		valuePerWin = tonumber(props.valuePerWin) or 0,
	}

	if Logic.isNotEmpty(props.localcurrency) and Logic.readBool(props.autoexchange) then
		Currency.display(props.localcurrency, nil, {setVariables = true})
		self.currencyRate = Currency.getExchangeRate{
			currency = props.localcurrency,
			currencyRate = Variables.varDefault('exchangerate_' .. props.localcurrency:upper()),
			date = DateExt.toYmdInUtc(endDate or DateExt.getContextualDateOrNow()),
			setVariables = false
		}
	end

	return HtmlWidgets.Div{children = {
		TableWidgets.Table{
			caption = props.title,
			tableClasses = {'prizepooltable', 'collapsed'},
			tableAttributes = {
				['data-cutafter'] = (tonumber(props.cutafter) or 5),
				['data-opentext'] = 'Show remaining participants',
				['data-closetext'] = 'Hide remaining participants',
			},
			columns = WidgetUtil.collect(
				{align = 'left'},
				(Logic.readBool(props.showMatchWL) or props.prizeMode == 'matchWins') and {align = 'center'} or nil,
				(Logic.readBool(props.showGameWL) or props.prizeMode == 'gameWins') and {align = 'center'} or nil,
				Logic.readBool(props.showScore) and {align = 'left'} or nil,
				Logic.isNotEmpty(props.localcurrency) and {align = 'right'} or nil,
				(Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency)) and {align = 'right'} or nil
			),
			children = {
				self:_headerRow(),
				TableWidgets.TableBody{children = Array.map(opponentList, FnUtil.curry(self._row, self))}
			},
		},
		Logic.readBool(props.showLegend) and self:_getLegendTable(valueByScore) or nil
		}
	}
end

---@private
---@return Widget
function StageWinnings:_headerRow()
	local props = self.props

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Participants'},
			(Logic.readBool(props.showMatchWL) or props.prizeMode == 'matchWins')
				and TableWidgets.CellHeader{children = 'Matches'} or nil,
			(Logic.readBool(props.showGameWL) or props.prizeMode == 'gameWins')
				and TableWidgets.CellHeader{children = 'Games'} or nil,
			Logic.readBool(props.showScore) and TableWidgets.CellHeader{children = 'Score Details'} or nil,
			Logic.isNotEmpty(props.localcurrency)
				and TableWidgets.CellHeader{children = Currency.display(props.localcurrency)} or nil,
			(Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency))
				and TableWidgets.CellHeader{children = Currency.display(BASE_CURRENCY)} or nil
		)}
	}}
end

---@private
---@param data {opponent: standardOpponent, matchWins: integer, matchLosses: integer, gameWins: integer,
---gameLosses: integer, winnings: number, scoreDetails: table<string, integer>}
---@return Widget
function StageWinnings:_row(data)
	local props = self.props

	local currencyDisplayConfig = {
		displaySymbol = true,
		formatValue = true,
		displayCurrencyCode = false,
		formatPrecision = tonumber(props.precision) or 0,
	}

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = OpponentDisplay.InlineOpponent{opponent = data.opponent}},
			(Logic.readBool(props.showMatchWL) or props.prizeMode == 'matchWins') and TableWidgets.Cell{
				children = {
					data.matchWins,
					'-',
					data.matchLosses
				},
			} or nil,
			(Logic.readBool(props.showGameWL) or props.prizeMode == 'gameWins') and TableWidgets.Cell{
				children = {
					data.gameWins,
					'-',
					data.gameLosses
				},
			} or nil,
			Logic.readBool(props.showScore) and TableWidgets.Cell{
				children = StageWinnings._detailedScores(data.scoreDetails),
			} or nil,
			Logic.isNotEmpty(props.localcurrency) and TableWidgets.Cell{
				children = Currency.display(
					props.localcurrency,
					data.winnings,
					currencyDisplayConfig
				),
			} or nil,
			(Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency)) and TableWidgets.Cell{
				children = Currency.display(
					BASE_CURRENCY,
					data.winnings * (self.currencyRate or 1),
					currencyDisplayConfig
				),
			} or nil
		),
	}
end

---@param scoresTable table<string, integer>
---@return (string|Widget)[]
function StageWinnings._detailedScores(scoresTable)
	---@type {wins: integer, losses: integer, count: integer}
	local scoreInfos = Array.extractValues(Table.map(scoresTable, function(score, count)
		local wins, losses = score:match('(%d+)%-(%d+)')
		return score, {wins = tonumber(wins), losses = tonumber(losses), count = count}
	end))
	table.sort(scoreInfos, function(a, b)
		local diffA = a.wins - a.losses
		local diffB = b.wins - b.losses
		if diffA ~= diffB then
			return diffA > diffB
		end
		return a.wins > b.wins
	end)

	return Array.interleave(
		Array.map(scoreInfos, function(scoreInfo)
			return scoreInfo.wins .. '-' .. scoreInfo.losses .. ': ' .. scoreInfo.count .. ' times'
		end),
		HtmlWidgets.Br{}
	)
end

---@param valueByScore table<string, integer>?
---@return Widget
function StageWinnings:_getLegendTable(valueByScore)
	local props = self.props

	local currencyDisplayConfig = {
		displaySymbol = true,
		formatValue = true,
		displayCurrencyCode = false,
		formatPrecision = tonumber(props.precision) or 0,
	}
	local showLocalCurrency = Logic.isNotEmpty(props.localcurrency)
	local showBaseCurrency = Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency)
	local currencyRate = self.currencyRate or 1

	---@param currency string
	---@param amount string?
	local function currencyCell(currency, amount)
		return TableWidgets.Cell{children = Currency.display(currency, tonumber(amount) or 0, currencyDisplayConfig)}
	end

	---@param amount string?
	local function localCurrencyCell(amount)
		return showLocalCurrency and currencyCell(props.localcurrency, amount) or nil
	end

	---@param amount string?
	local function baseCurrencyCell(amount)
		return showBaseCurrency and currencyCell(BASE_CURRENCY, amount * currencyRate) or nil
	end

	local sortedScoreEntries = Array.extractValues(Table.map(valueByScore or {}, function(scoreline, prize)
		local wins, losses = scoreline:match('^(%d+)%-(%d+)$')
		return scoreline, {
			scoreline = scoreline,
			prize = prize,
			wins = tonumber(wins),
			losses = tonumber(losses),
		}
	end))
	table.sort(sortedScoreEntries, function(a, b)
		if a.wins ~= nil and b.wins ~= nil then
			local diffA = a.wins - a.losses
			local diffB = b.wins - b.losses
			if diffA ~= diffB then
				return diffA > diffB
			end
			if a.wins ~= b.wins then
				return a.wins > b.wins
			end
			if a.losses ~= b.losses then
				return a.losses < b.losses
			end
			return a.scoreline < b.scoreline
		end
		if a.wins ~= nil then
			return true
		end
		if b.wins ~= nil then
			return false
		end
		return a.scoreline < b.scoreline
	end)

	return TableWidgets.Table{
		caption = props.legendTitle or 'Prize Distribution',
		columns = WidgetUtil.collect(
			{align = 'left'},
			showLocalCurrency and {align = 'right'} or nil,
			showBaseCurrency and {align = 'right'} or nil
		),
		children = {
			TableWidgets.TableHeader{children = {
				TableWidgets.Row{children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = 'Score'},
					showLocalCurrency
						and TableWidgets.CellHeader{children = Currency.display(props.localcurrency)} or nil,
					showBaseCurrency
						and TableWidgets.CellHeader{children = Currency.display(BASE_CURRENCY)} or nil
				)}
			}},
			TableWidgets.TableBody{children = WidgetUtil.collect(
				tonumber(props.valueStart) and TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.Cell{children = 'Starting Prize'},
						localCurrencyCell(props.valueStart),
						baseCurrencyCell(props.valueStart)
					)
				} or nil,
				(props.prizeMode == 'matchWins' or props.prizeMode == 'gameWins') and TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.Cell{children = props.prizeMode == 'matchWins' and 'Match Win' or 'Game Win'},
						localCurrencyCell(props.valuePerWin),
						baseCurrencyCell(props.valuePerWin)
					)
				} or nil,
				props.prizeMode == 'scores' and WidgetUtil.collect(Array.map(sortedScoreEntries, function(scoreEntry)
					return TableWidgets.Row{children = WidgetUtil.collect(
						TableWidgets.Cell{children = scoreEntry.scoreline},
						localCurrencyCell(scoreEntry.prize),
						baseCurrencyCell(scoreEntry.prize)
					)}
				end)) or nil
			)}
		}
	}
end

return StageWinnings

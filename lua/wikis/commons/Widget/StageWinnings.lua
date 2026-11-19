---
-- @Liquipedia
-- page=Module:Widget/StageWinnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Points = Lua.import('Module:Points/data', {loadData = true})
local StageWinningsCalculation = Lua.import('Module:StageWinningsCalculation')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Link = Lua.import('Module:Widget/Basic/Link')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BASE_CURRENCY = 'USD'
local NON_BREAKING_SPACE = '&nbsp;'

---@class StageWinningProps
---@field tournament1 string?
---@field tournament2 string?
---@field tournament3 string?
---@field matchGroupId1 string?
---@field matchGroupId2 string?
---@field matchGroupId3 string?
---@field sdate string|number|osdate|osdateparam?
---@field edate string|number|osdate|osdateparam?
---@field prizeMode 'matchWins'|'gameWins'|'scores'?
---@field points string?
---@field points2 string?
---@field valueStart number?
---@field valuePerWin number?
---@field pointsStart number?
---@field pointsPerWin number?
---@field points2Start number?
---@field points2PerWin number?
---@field gameCountDefaultResult number?
---@field n-m number? # n amd m integers
---@field n-m_points number? # n amd m integers
---@field n-m_points2 number? # n amd m integers
---@field localcurrency string?
---@field collapseafter integer?
---@field cutafter integer? # deprecated alias of collapseafter
---@field title string?
---@field precision integer?
---@field autoexchange boolean?
---@field showMatchWL boolean?
---@field showGameWL boolean?
---@field showScore boolean?
---@field hideWinnings boolean?

---@alias StageWinningsPointsData {title: string, icon: string?, iconDark: string?, link: string?, titleLong: string?}

local defaultProps = {
	autoexchange = true,
	prizeMode = 'matchWins',
	title = 'Group Stage Winnings'
}

local StageWinnings = {}

---@param props StageWinningProps
---@return VNode
local function StageWinningsWidget(props)
	local startDate = DateExt.readTimestamp(props.sdate)
	local endDate = DateExt.readTimestamp(props.edate)

	local getValuesByScore = function(postFix)
		local valueByScore = Table.filterByKey(props, function(key)
			if key:match('^%d+%-%d+' .. postFix .. '$') ~= nil then
				return true
			end
			local keyParts = Array.parseCommaSeparatedString((key:gsub(postFix, '')), '-')
			return #keyParts == 2 and
				Array.all(keyParts, function(keyPart) return Table.includes(MatchGroupInputUtil.STATUS, keyPart) end)
		end)
		return Table.map(valueByScore, function(key, value)
			local newKey = key:gsub(postFix, '')
			return newKey, tonumber(value)
		end)
	end

	local valueByScore = getValuesByScore('')
	local pointsByScore = getValuesByScore('_points')
	local points2ByScore = getValuesByScore('_points2')

	assert(props.prizeMode == 'matchWins' or props.prizeMode == 'gameWins' or props.prizeMode == 'scores',
		'Invalid prizeMode input')
	assert(props.prizeMode ~= 'scores' or Logic.isNotEmpty(valueByScore) or Logic.isNotEmpty(pointsByScore),
		'No values per scores defined')

	local opponentList = StageWinningsCalculation.run{
		matchGroupsSpecProps = Table.filterByKey(props, function(key)
			return String.startsWith(key, 'tournament') or String.startsWith(key, 'matchGroupId')
		end) --[[@as table<string, string>]],
		startDate = startDate,
		endDate = endDate,
		mode = props.prizeMode,
		valueByScore = valueByScore,
		pointsByScore = pointsByScore,
		points2ByScore = points2ByScore,
		startValue = tonumber(props.valueStart) or 0,
		pointsStart = tonumber(props.pointsStart) or 0,
		points2Start = tonumber(props.points2Start) or 0,
		valuePerWin = tonumber(props.valuePerWin) or 0,
		pointsPerWin = tonumber(props.pointsPerWin) or 0,
		points2PerWin = tonumber(props.points2PerWin) or 0,
		hideWinnings = Logic.readBool(props.hideWinnings),
		gameCountDefaultResult = tonumber(props.gameCountDefaultResult),
	}

	---@type number?
	local currencyRate
	if Logic.isNotEmpty(props.localcurrency) and Logic.readBool(props.autoexchange) then
		currencyRate = Currency.getExchangeRate{
			currency = props.localcurrency,
			date = DateExt.toYmdInUtc(endDate or DateExt.getContextualDateOrNow()),
			setVariables = false
		}
	end

	---@param prefix string
	---@return StageWinningsPointsData?
	local parsePoints = function(prefix)
		if Logic.isEmpty(props[prefix]) then
			return
		end

		local pointsData = Table.copy(Points[props[prefix]] or {})
		pointsData.title = pointsData.title or props[prefix]
		pointsData.link = props[prefix .. 'link']

		return pointsData
	end
	local pointsData = parsePoints('points')
	local points2Data = parsePoints('points2')

	local collapseAfter = tonumber(props.collapseafter or props.cutafter) or 5

	return TableWidgets.Table{
		caption = props.title,
		collapseAfter = #opponentList > collapseAfter and collapseAfter or nil,
		expandText = 'Show remaining participants',
		collapseText = 'Hide remaining participants',
		columns = WidgetUtil.collect(
			{align = 'left'},
			(Logic.readBool(props.showMatchWL) or props.prizeMode == 'matchWins') and {align = 'center'} or nil,
			(Logic.readBool(props.showGameWL) or props.prizeMode == 'gameWins') and {align = 'center'} or nil,
			Logic.readBool(props.showScore) and {align = 'left'} or nil,
			Logic.isNotEmpty(props.localcurrency) and {align = 'right'} or nil,
			(Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency))
				and (not Logic.readBool(props.hideWinnings)) and {align = 'right'}
				or nil,
			Logic.isNotEmpty(pointsData) and {align = 'right'} or nil,
			Logic.isNotEmpty(points2Data) and {align = 'right'} or nil
		),
		children = {
			StageWinnings._headerRow(props, pointsData, points2Data),
			TableWidgets.TableBody{children = Array.map(opponentList, function(data)
				return StageWinnings._row(props, currencyRate, pointsData, points2Data, data)
			end)}
		},
	}
end

---@private
---@param props StageWinningProps
---@param pointsData StageWinningsPointsData?
---@param points2Data StageWinningsPointsData?
---@return VNode
function StageWinnings._headerRow(props, pointsData, points2Data)
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
				and (not Logic.readBool(props.hideWinnings))
				and TableWidgets.CellHeader{children = Currency.display(BASE_CURRENCY)} or nil,
			StageWinnings._pointsHeader(pointsData),
			StageWinnings._pointsHeader(points2Data)
		)}
	}}
end

---@private
---@param props StageWinningProps
---@param currencyRate number?
---@param pointsData StageWinningsPointsData?
---@param points2Data StageWinningsPointsData?
---@param data {opponent: standardOpponent, matchWins: integer, matchLosses: integer, gameWins: integer,
---gameLosses: integer, winnings: number, points: number, points2: number, scoreDetails: table<string, integer>}
---@return VNode
function StageWinnings._row(props, currencyRate, pointsData, points2Data, data)
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
			(Logic.readBool(props.autoexchange) or Logic.isEmpty(props.localcurrency))
				and (not Logic.readBool(props.hideWinnings)) and TableWidgets.Cell{children = Currency.display(
					BASE_CURRENCY,
					data.winnings * (currencyRate or 1),
					currencyDisplayConfig
				)} or nil,
			Logic.isNotEmpty(pointsData) and TableWidgets.Cell{
				children = Currency.formatMoney(data.points, 2, false, true),
				['data-sort-value'] = data.points,
			} or nil,
			Logic.isNotEmpty(points2Data) and TableWidgets.Cell{
				children = Currency.formatMoney(data.points2, 2, false, true),
				['data-sort-value'] = data.points2,
			} or nil
		),
	}
end

---@private
---@param scoresTable table<string, integer>
---@return Renderable[]
function StageWinnings._detailedScores(scoresTable)
	---@type {wins: integer, losses: integer, count: integer}
	local scoreInfos = Array.extractValues(Table.map(scoresTable, function(score, count)
		local wins, losses = unpack(Array.parseCommaSeparatedString(score, '-'))
		return score, {wins = tonumber(wins) or wins, losses = tonumber(losses) or losses, count = count}
	end))
	table.sort(scoreInfos, function(a, b)
		if (not Logic.isNumeric(a.wins)) or (not Logic.isNumeric(a.losses)) then
			return false
		elseif (not Logic.isNumeric(b.wins)) or (not Logic.isNumeric(b.losses)) then
			return true
		end
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
		Html.Br{}
	)
end

---@private
---@param data StageWinningsPointsData?
---@return VNode?
function StageWinnings._pointsHeader(data)
	if not data then
		return
	end

	local titleText = Logic.isNotEmpty(data.titleLong) and Html.Abbr{
		children = data.title, title = data.titleLong
	} or data.title

	return TableWidgets.CellHeader{children = WidgetUtil.collect(
		Logic.isNotEmpty(data.icon) and {
			LeagueIcon.display{link = data.link, icon = data.icon, iconDark = data.iconDark, name = data.title},
			NON_BREAKING_SPACE,
		} or nil,
		Logic.isNotEmpty(data.link) and Link{link = data.link, children = titleText} or titleText
	)}
end

return Component.component(StageWinningsWidget, defaultProps)
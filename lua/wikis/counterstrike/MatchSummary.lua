---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local VodLink = Lua.import('Module:VodLink')

local Html = Lua.import('Module:Widget/Html')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CounterstrikeCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class CounterstrikeMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local CounterstrikeMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return Renderable
function CustomMatchSummary.createFooter(match)
	local vods = {}
	local secondVods = {}
	if Logic.isNotEmpty(match.links.vod2) then
		for _, vod2 in ipairs(match.links.vod2) do
			local link, gameIndex = unpack(vod2)
			secondVods[gameIndex] = Array.parseCommaSeparatedString(link)
		end
		match.links.vod2 = nil
	end
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	if Table.isNotEmpty(vods) or Table.isNotEmpty(match.links) or Logic.isNotEmpty(match.vod) then
		return CustomMatchSummary._createFooter(match, vods, secondVods)
	end

	return MatchSummary.createDefaultFooter(match)
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	if Logic.isNotEmpty(match.extradata.status) then
		match.stream = {rawdatetime = true}
	end
	local matchStatusText = match.extradata.status and Html.B{children = {
		'Match ',
		String.upperCaseFirst(match.extradata.status)
	}} or nil
	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if Logic.isEmpty(game.map) then
					return
				end
				return CounterstrikeMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.MatchComment{children = {matchStatusText}} or nil
	)
end

---@param match MatchGroupUtilMatch
---@param vods table<integer, string>
---@param secondVods table<integer, table>
---@return Renderable
function CustomMatchSummary._createFooter(match, vods, secondVods)
	local elements = {}
	local separator = '<b>·</b>'

	local function addFooterLink(icon, iconDark, url, label, index)
		if icon == 'stats' then
			icon = index ~= 0 and 'Match Info Stats' .. index .. '.png' or 'Match Info Stats.png'
		end
		if index > 0 then
			label = label .. ' for Game ' .. index
		end

		table.insert(elements, MatchSummary.makeLinkDisplay(url, icon, iconDark, label))
	end

	local function addVodLink(gamenum, vod, part)
		if vod then
			gamenum = (gamenum and match.bestof > 1) and gamenum or nil
			local htext
			if part then
				if gamenum then
					htext = 'Watch Game ' .. gamenum .. ' (part ' .. part .. ')'
				else
					htext = 'Watch VOD (part ' .. part .. ')'
				end
			end
			table.insert(elements, VodLink.display{
				gamenum = gamenum,
				vod = vod,
				htext = htext
			})
		end
	end

	-- Match vod
	if Table.isNotEmpty(secondVods[0]) then
		addVodLink(nil, match.vod, 1)
		Array.forEach(secondVods[0], function(vodlink, vodindex)
			addVodLink(nil, vodlink, vodindex + 1)
		end)
	else
		addVodLink(nil, match.vod, nil)
	end

	-- Game Vods
	for index, vod in pairs(vods) do
		if Table.isNotEmpty(secondVods[index]) then
			addVodLink(index, vod, 1)
			Array.forEach(secondVods[index], function(vodlink, vodindex)
				addVodLink(index, vodlink, vodindex + 1)
			end)
		else
			addVodLink(index, vod, nil)
		end
	end

	if Table.isEmpty(match.links) then
		return MatchSummaryWidgets.Footer{children = elements}
	end

	if Table.isNotEmpty(elements) then
		table.insert(elements, separator)
	end

	--- Platforms is used to keep the order of the links in footer
	local platforms = Lua.import('Module:MatchExternalLinks', {loadData = true})
	local links = match.links

	local insertDotNext = false
	local iconsInserted = 0

	Array.forEach(platforms, function(platform)
		if Logic.isEmpty(platform) then
			insertDotNext = iconsInserted > 0 and true or false
			return
		end
		local link = links[platform.name]
		if not link then
			return
		end

		if insertDotNext then
			insertDotNext = false
			iconsInserted = 0
			table.insert(elements, separator)
		end

		local icon = platform.icon
		local iconDark = platform.iconDark
		local label = platform.label
		local addGameLabel = platform.isMapStats and match.bestof and match.bestof > 1

		Array.forEach(link, function(val)
			addFooterLink(icon, iconDark, val[1], label, addGameLabel and val[2] or 0)
			iconsInserted = iconsInserted + 1
		end)

		if platform.stats then
			for _, site in ipairs(platform.stats) do
				if links[site] then
					table.insert(elements, separator)
					break
				end
			end
		end
	end)

	return MatchSummaryWidgets.Footer{children = elements}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game

	local sides = game.extradata['t' .. opponentIndex .. 'sides']
	local halfs = game.extradata['t' .. opponentIndex .. 'halfs']
	local scores = Array.map(sides, function (side, sideIndex)
		return {style = side and ('brkts-cs-score-color-'.. side) or nil, score = halfs[sideIndex]}
	end)

	return MatchSummaryWidgets.DetailedScore{
		score = MatchSummaryWidgets.GameRow.scoreDisplay(game, opponentIndex),
		partialScores = scores,
	}
end

return CustomMatchSummary

---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	local vods = {}
	local secondVods = {}
	if Logic.isNotEmpty(match.links.vod2) then
		for _, vod2 in ipairs(match.links.vod2) do
			local link, gameIndex = unpack(vod2)
			secondVods[gameIndex] = Array.map(mw.text.split(link, ','), String.trim)
		end
		match.links.vod2 = nil
	end
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) or not Logic.isEmpty(match.vod) then
		return CustomMatchSummary._createFooter(match, vods, secondVods)
	end

	return footer
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	if Logic.isNotEmpty(match.extradata.status) then
		match.stream = {rawdatetime = true}
	end
	local matchStatusText
	if match.extradata.status then
		matchStatusText = '<b>Match ' .. mw.getContentLanguage():ucfirst(match.extradata.status) .. '</b>'
	end
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMap),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.MatchComment{children = matchStatusText} or nil
	)}
end

---@param match MatchGroupUtilMatch
---@param vods table<integer, string>
---@param secondVods table<integer, table>
---@return MatchSummaryFooter
function CustomMatchSummary._createFooter(match, vods, secondVods)
	local footer = MatchSummary.Footer()

	local separator = '<b>·</b>'

	local function addFooterLink(icon, iconDark, url, label, index)
		if icon == 'stats' then
			icon = index ~= 0 and 'Match Info Stats' .. index .. '.png' or 'Match Info Stats.png'
		end
		if index > 0 then
			label = label .. ' for Game ' .. index
		end

		icon = 'File:' .. icon
		if iconDark then
			iconDark = 'File:' .. iconDark
		end

		footer:addLink(url, icon, iconDark, label)
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
			footer:addElement(VodLink.display{
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

	if Table.isNotEmpty(match.links) then
		if Logic.isNotEmpty(vods) or match.vod then
			footer:addElement(separator)
		end
	else
		return footer
	end

	--- Platforms is used to keep the order of the links in footer
	local platforms = mw.loadData('Module:MatchExternalLinks')
	local links = match.links

	local insertDotNext = false
	local iconsInserted = 0

	for _, platform in ipairs(platforms) do
		if Logic.isNotEmpty(platform) then
			local link = links[platform.name]
			if link then
				if insertDotNext then
					insertDotNext = false
					iconsInserted = 0
					footer:addElement(separator)
				end

				local icon = platform.icon
				local iconDark = platform.iconDark
				local label = platform.label
				local addGameLabel = platform.isMapStats and match.bestof and match.bestof > 1

				for _, val in ipairs(link) do
					addFooterLink(icon, iconDark, val[1], label, addGameLabel and val[2] or 0)
					iconsInserted = iconsInserted + 1
				end

				if platform.stats then
					for _, site in ipairs(platform.stats) do
						if links[site] then
							footer:addElement(separator)
							break
						end
					end
				end
			end
		else
			insertDotNext = iconsInserted > 0 and true or false
		end
	end

	return footer
end

---@param game MatchGroupUtilGame
---@return Html?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
	end

	-- Teams scores
	local t1sides = extradata.t1sides or {}
	local t2sides = extradata.t2sides or {}
	local t1halfs = extradata.t1halfs or {}
	local t2halfs = extradata.t2halfs or {}

	local team1Scores = {}
	local team2Scores = {}
	for sideIndex in ipairs(t1sides) do
		local side1, side2 = t1sides[sideIndex], t2sides[sideIndex]
		local score1, score2 = t1halfs[sideIndex], t2halfs[sideIndex]
		table.insert(team1Scores, {style = side1 and ('brkts-cs-score-color-'.. side1) or nil, score = score1})
		table.insert(team2Scores, {style = side2 and ('brkts-cs-score-color-'.. side2) or nil, score = score2})
	end

	-- Map Info
	local mapInfo = mw.html.create('div')
	mapInfo	:addClass('brkts-popup-spaced')
			:wikitext(CustomMatchSummary._createMapLink(game.map, game.game))
			:css('text-align', 'center')
			:css('padding','5px 2px')
			:css('flex-grow','1')

	if game.resultType == 'np' then
		mapInfo:addClass('brkts-popup-spaced-map-skip')
	elseif game.resultType == 'draw' then
		mapInfo:wikitext('<i>(Draw)</i>')
	end

	-- Build the HTML
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(MatchSummaryWidgets.DetailedScore{score = scoreDisplay(1), partialScores = team1Scores})

	row:addElement(mapInfo)

	row:addElement(MatchSummaryWidgets.DetailedScore{score = scoreDisplay(2), partialScores = team2Scores})
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game'):css('font-size', '85%'):css('overflow', 'hidden')

	return row:create()
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if isWinner then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param map string?
---@param game string?
---@return string
function CustomMatchSummary._createMapLink(map, game)
	if Logic.isNotEmpty(map) then
		if Logic.isNotEmpty(game) then
			return '[[' .. map .. '/' .. game .. '|' .. map .. ']]'
		else
			return '[[' .. map .. '|' .. map .. ']]'
		end
	end
	return ''
end

return CustomMatchSummary

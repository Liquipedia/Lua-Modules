---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
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

-- Score Class
---@class CounterstrikeScore
---@operator call: CounterstrikeScore
---@field root Html
---@field table Html
---@field top Html
---@field bottom Html
local Score = Class.new(
	function(self, direction)
		self.root = mw.html.create('div')
			:css('width','70px')
			:css('text-align', 'center')
			:css('direction', direction)
		self.table = self.root:tag('table'):css('line-height', '29px')
		self.top = mw.html.create('tr')
		self.bottom = mw.html.create('tr')
	end
)

---@return self
function Score:setLeft()
	self.table:css('float', 'left')
	return self
end

---@return self
function Score:setRight()
	self.table:css('float', 'right')
	return self
end

---@param score string|number|nil
---@return self
function Score:setMapScore(score)
	local mapScore = mw.html.create('td')
	mapScore
		:attr('rowspan', 2)
		:css('font-size', '16px')
		:css('width', '25px')
		:wikitext(score or '')

	self.top:node(mapScore)

	return self
end

---@param side string
---@param score number
---@return self
function Score:setFirstHalfScore(score, side)
	local halfScore = mw.html.create('td')
	halfScore
		:addClass('brkts-popup-body-match-sidewins')
		:addClass('brkts-cs-score-color-' .. side)
		:wikitext(score)

	self.top:node(halfScore)
	return self
end

---@param side string
---@param score number
---@return self
function Score:setSecondHalfScore(score, side)
	local halfScore = mw.html.create('td')
	halfScore
		:addClass('brkts-popup-body-match-sidewins')
		:addClass('brkts-cs-score-color-' .. side)
		:wikitext(score)

	self.bottom:node(halfScore)
	return self
end

---@return Html
function Score:create()
	self.table:node(self.top):node(self.bottom)
	return self.root
end

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

	local mapVeto = MatchSummary.defaultMapVetoDisplay(match.extradata.mapveto, {game = match.game})

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMap),
		mapVeto and mapVeto:create() or nil,
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
---@return MatchSummaryRow?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
	end

	-- Score
	local team1Score = Score():setLeft()
	local team2Score = Score('rtl'):setRight()

	-- Teams map score
	team1Score:setMapScore(scoreDisplay(1))
	team2Score:setMapScore(scoreDisplay(2))

	local t1sides = extradata['t1sides'] or {}
	local t2sides = extradata['t2sides'] or {}
	local t1halfs = extradata['t1halfs'] or {}
	local t2halfs = extradata['t2halfs'] or {}

	-- Teams half scores
	for sideIndex, side in ipairs(t1sides) do
		local oppositeSide = t2sides[sideIndex]
		if math.fmod(sideIndex, 2) == 1 then
			team1Score:setFirstHalfScore(t1halfs[sideIndex], side)
			team2Score:setFirstHalfScore(t2halfs[sideIndex], oppositeSide)
		else
			team1Score:setSecondHalfScore(t1halfs[sideIndex], side)
			team2Score:setSecondHalfScore(t2halfs[sideIndex], oppositeSide)
		end
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
	row:addElement(team1Score:create())

	row:addElement(mapInfo)

	row:addElement(team2Score:create())
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

	return row
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

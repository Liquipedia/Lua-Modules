---
-- @Liquipedia
-- wiki=zula
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

-- Score Class
---@class ZulaScore
---@operator call(string|number|nil): ZulaScore
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

---@return ZulaScore
function Score:setLeft()
	self.table:css('float', 'left')
	return self
end

---@return ZulaScore
function Score:setRight()
	self.table:css('float', 'right')
	return self
end

---@param score string|number|nil
---@return ZulaScore
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
---@return ZulaScore
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
---@return ZulaScore
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

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		if Logic.isNotEmpty(match.extradata.status) then
			match.stream = {rawdatetime = true}
		end
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default date, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		body:addRow(CustomMatchSummary._createMap(game))
	end

	-- Add the Map Vetoes
	body:addRow(MatchSummary.defaultMapVetoDisplay(match))

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow?
function CustomMatchSummary._createMap(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	-- Score
	local team1Score = Score():setLeft()
	local team2Score = Score('rtl'):setRight()

	-- Teams map score
	team1Score:setMapScore(DisplayHelper.MapScore(game.scores[1], 1, game.resultType, game.walkover, game.winner))
	team2Score:setMapScore(DisplayHelper.MapScore(game.scores[2], 2, game.resultType, game.walkover, game.winner))

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
			:wikitext('[[' .. game.map .. ']]')
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
		return container:node(GREEN_CHECK)
	end
	return container:node(NO_CHECK)
end

return CustomMatchSummary

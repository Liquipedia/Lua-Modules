---
-- @Liquipedia
-- wiki=criticalops
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base/temp', {requireDevIfEnabled = true})

local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'

local EPOCH_TIME = '1970-01-01 00:00:00'
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local TBD = 'TBD'

-- Score Class
---@class CriticalopsScore
---@operator call(string|number|nil): CriticalopsScore
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

---@return CriticalopsScore
function Score:setLeft()
	self.table:css('float', 'left')
	return self
end

---@return CriticalopsScore
function Score:setRight()
	self.table:css('float', 'right')
	return self
end

---@param score string|number|nil
---@return CriticalopsScore
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
---@return CriticalopsScore
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
---@return CriticalopsScore
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

-- Map Veto Class
---@class CriticalopsMapVeto: MatchSummaryRowInterface
---@operator call: CriticalopsMapVeto
---@field root Html
---@field table Html
local MapVeto = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

---@return CriticalopsMapVeto
function MapVeto:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','33%'):done()
		:tag('th'):css('width','34%'):wikitext('Map Veto'):done()
		:tag('th'):css('width','33%'):done()
	return self
end

---@param firstVeto number?
---@return CriticalopsMapVeto
function MapVeto:vetoStart(firstVeto)
	local textLeft
	local textCenter
	local textRight
	if firstVeto == 1 then
		textLeft = '<b>Start Map Veto</b>'
		textCenter = ARROW_LEFT
	elseif firstVeto == 2 then
		textCenter = ARROW_RIGHT
		textRight = '<b>Start Map Veto</b>'
	else return self end
	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft or ''):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight or ''):done()
	return self
end

---@param map string?
---@return CriticalopsMapVeto
function MapVeto:addDecider(map)
	map = Logic.emptyOr(map, TBD)

	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', 'DECIDER')
	self:addColumnVetoMap(row, map)
	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', 'DECIDER')

	self.table:node(row)
	return self
end

---@param vetotype string?
---@param map1 string?
---@param map2 string?
---@return CriticalopsMapVeto
function MapVeto:addRound(vetotype, map1, map2)
	map1 = Logic.emptyOr(map1, TBD)
	map2 = Logic.emptyOr(map2, TBD)

	local class
	local vetoText
	if vetotype == 'ban' then
		vetoText = 'BAN'
		class = 'brkts-popup-mapveto-ban'
	elseif vetotype == 'pick' then
		vetoText = 'PICK'
		class = 'brkts-popup-mapveto-pick'
	elseif vetotype == 'defaultban' then
		vetoText = 'DEFAULT BAN'
		class = 'brkts-popup-mapveto-defaultban'
	else
		return self
	end

	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoMap(row, map1)
	self:addColumnVetoType(row, class, vetoText)
	self:addColumnVetoMap(row, map2)

	self.table:node(row)
	return self
end

---@param row Html
---@param styleClass string
---@param vetoText string
---@return CriticalopsMapVeto
function MapVeto:addColumnVetoType(row, styleClass, vetoText)
	row:tag('td')
		:tag('span')
			:addClass(styleClass)
			:addClass('brkts-popup-mapveto-vetotype')
			:wikitext(vetoText)
	return self
end

---@param row Html
---@param map string
---@return CriticalopsMapVeto
function MapVeto:addColumnVetoMap(row, map)
	row:tag('td'):wikitext(map):done()
	return self
end

---@return Html
function MapVeto:create()
	return self.root
end

---@class CriticalopsMatchStatus: MatchSummaryRowInterface
---@operator call: CriticalopsMatchStatus
---@field root Html
local MatchStatus = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root
			:addClass('brkts-popup-comment')
			:css('white-space', 'normal')
			:css('font-size', '85%')
	end
)

---@param content Html|string|number|nil
---@return CriticalopsMatchStatus
function MatchStatus:content(content)
	self.root:node(content):node(MatchSummary.Break():create())
	return self
end

---@return Html
function MatchStatus:create()
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

	if match.dateIsExact or (match.date ~= EPOCH_TIME_EXTENDED and match.date ~= EPOCH_TIME) then
		if Logic.isNotEmpty(match.extradata.status) then
			match.stream = {rawdatetime = true}
		end
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMap(game))
		end
	end

	-- Add the Map Vetoes
	if match.extradata.mapveto then
		local vetoData = match.extradata.mapveto
		if vetoData then
			local mapVeto = MapVeto()

			for _,vetoRound in ipairs(vetoData) do
				if vetoRound.vetostart then
					mapVeto:vetoStart(tonumber(vetoRound.vetostart))
				end
				if vetoRound.type == 'decider' then
					mapVeto:addDecider(vetoRound.decider)
				else
					mapVeto:addRound(vetoRound.type, vetoRound.team1, vetoRound.team2)
				end
			end

			body:addRow(mapVeto)
		end
	end

	-- Match Status (postponed/ cancel(l)ed)
	if match.extradata.status then
		local matchStatus = MatchStatus()
		matchStatus:content('<b>Match ' .. mw.getContentLanguage():ucfirst(match.extradata.status) .. '</b>')
		body:addRow(matchStatus)
	end

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createMap(game)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	-- Score
	local team1Score = Score():setLeft()
	local team2Score = Score('rtl'):setRight()

	-- Teams map score
	team1Score:setMapScore(game.scores[1])
	team2Score:setMapScore(game.scores[2])

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
		row:addElement(MatchSummary.Break():create())
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

return CustomMatchSummary

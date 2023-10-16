---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local StrikerIcon = require('Module:StrikerIcon')
local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Json = require('Module:Json')

local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local _EPOCH_TIME = '1970-01-01 00:00:00'
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local htmlCreate = mw.html.create

local _GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local _ICONS = {
	check = _GREEN_CHECK,
}
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
local LINK_DATA = {
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'LiveReport.png'},
}


local CustomMatchSummary = {}


-- Striker Pick/Ban Class
local Striker = Class.new(
	function(self, options)
		options = options or {}
		self.isBan = options.isBan
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto')
		self.table = self.root:tag('table')
			:addClass('wikitable-striped'):addClass('collapsible'):addClass('collapsed')
		self:createHeader()
	end
)

function Striker:createHeader(text)
	self.table:tag('tr')
		:tag('th'):css('width','40%'):wikitext(''):done()
		:tag('th'):css('width','20%'):wikitext(self.isBan and 'Bans' or 'Picks'):done()
		:tag('th'):css('width','40%'):wikitext(''):done()
	return self
end

function Striker:row(strikerData, gameNumber, numberStrikers, date)
	if numberStrikers > 0 then
		self.table:tag('tr')
			:tag('td')
				:node(self:_opponentStrikerDisplay(strikerData[1], numberStrikers, false, date))
			:tag('td')
				:node(mw.html.create('div')
					:wikitext(Abbreviation.make(
							'Map ' .. gameNumber,
							(self.isBan and 'Bans' or 'Picks') .. ' in game ' .. gameNumber
						)
					)
				)
			:tag('td')
				:node(self:_opponentStrikerDisplay(strikerData[2], numberStrikers, true, date))
	end

	return self
end

function Striker:_opponentStrikerDisplay(strikerData, numberOfStrikers, flip, date)
	local opponentStrikerDisplay = {}

	for index = 1, numberOfStrikers do
		local strikerDisplay = mw.html.create('div')
			:addClass('brkts-popup-side-color-' .. (flip and 'red' or 'blue'))
			:css('float', flip and 'right' or 'left')
			:node(StrikerIcon._getImage{
				striker = strikerData[index],
				class = 'brkts-champion-icon',
				date = date,
			})
		if index == 1 then
			strikerDisplay:css('padding-left', '2px')
		elseif index == numberOfStrikers then
			strikerDisplay:css('padding-right', '2px')
		end
		table.insert(opponentStrikerDisplay, strikerDisplay)
	end

	if flip then
		opponentStrikerDisplay = Array.reverse(opponentStrikerDisplay)
	end

	local display = mw.html.create('div')
	if self.isBan then
		display:addClass('brkts-popup-side-shade-out')
		display:css('padding-' .. (flip and 'right' or 'left'), '4px')
	end

	for _, item in ipairs(opponentStrikerDisplay) do
		display:node(item)
	end

	return display
end

function Striker:create()
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
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer:addLinks(MatchLinks, match.links)
end

function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.date ~= _EPOCH_TIME_EXTENDED and match.date ~= _EPOCH_TIME) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createMapRow(game))
		end
	end

	-- Add Match MVP(s)
	local mvpInput = match.extradata.mvp
	if mvpInput then
		local mvpData = mw.text.split(mvpInput or '', ',')
		if String.isNotEmpty(mvpData[1]) then
			local mvp = MatchSummary.Mvp()
			for _, player in ipairs(mvpData) do
				if String.isNotEmpty(player) then
					mvp:addPlayer(player)
				end
			end

			body:addRow(mvp)
		end
	end

	-- Pre-Process Striker picks
	local showGamePicks = {}
	for gameIndex, game in ipairs(match.games) do
		local pickData = {{}, {}}
		local numberOfPicks = game.extradata.maximumpickindex
		local participants = game.participants
		for index = 1, numberOfPicks do
			if not Table.isEmpty(participants['1_' .. index]) then
				pickData[1][index] = participants['1_' .. index].striker
			end
			if not Table.isEmpty(participants['2_' .. index]) then
				pickData[2][index] = participants['2_' .. index].striker
			end
		end

		if numberOfPicks > 0 then
			pickData.numberOfPicks = numberOfPicks
			showGamePicks[gameIndex] = pickData
		end
	end

	-- Add the Striker picks
	if not Table.isEmpty(showGamePicks) then
		local striker = Striker({isBan = false})

		for gameIndex, pickData in ipairs(showGamePicks) do
			striker:row(pickData, gameIndex, pickData.numberOfPicks, match.date)
		end

		body:addRow(striker)
	end

	-- Pre-Process Striker bans
	local showGameBans = {}
	for gameIndex, game in ipairs(match.games) do
		local extradata = game.extradata
		local bans = Json.parseIfString(extradata.bans or '{}')
		if not Table.isEmpty(bans) then
			bans.numberOfBans = math.max(#bans.team1, #bans.team2)
			if bans.numberOfBans > 0 then
				bans[1] = bans.team1
				bans[2] = bans.team2
				showGameBans[gameIndex] = bans
			end
		end
	end

	-- Add the Striker bans
	if not Table.isEmpty(showGameBans) then
		local striker = Striker({isBan = true})

		for gameIndex, banData in ipairs(showGameBans) do
			striker:row(banData, gameIndex, banData.numberOfBans, match.date)
		end

		body:addRow(striker)
	end

	return body
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] or ''
	return htmlCreate('div'):wikitext(score)
end

function CustomMatchSummary._createMapRow(game)
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = htmlCreate('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, 'check'))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = htmlCreate('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2, 'check'))

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	row:addClass('brkts-popup-body-game')
		:css('overflow', 'hidden')

	-- Add Comment
	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = htmlCreate('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'
	return mapDisplay
end

function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = htmlCreate('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		container:node(_ICONS[iconType])
	else
		container:node(_NO_CHECK)
	end

	return container
end

return CustomMatchSummary

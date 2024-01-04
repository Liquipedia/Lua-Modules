---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local StrikerIcon = require('Module:StrikerIcon')
local Table = require('Module:Table')

local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local EPOCH_TIME = '1970-01-01 00:00:00'
local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local ICONS = {
	check = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>',
	empty = '[[File:NoCheck.png|link=]]'
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
	return MatchSummary.addVodsToFooter(match, footer)
end

function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.date ~= EPOCH_TIME_EXTENDED and match.date ~= EPOCH_TIME) then
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

	-- Pre-Process Striker picks
	local showGamePicks = {}
	for gameIndex, game in ipairs(match.games) do
		local pickData = {{}, {}}
		local numberOfPicks = game.extradata.maximumpickindex or 0
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
		local striker = Striker{isBan = false}

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
		local striker = Striker{isBan = true}

		for gameIndex, banData in ipairs(showGameBans) do
			striker:row(banData, gameIndex, banData.numberOfBans, match.date)
		end

		body:addRow(striker)
	end

	return body
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div'):wikitext(game.scores[opponentIndex])
end

function CustomMatchSummary._createMapRow(game)
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext(Page.makeInternalLink(game.map))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1, 'check'))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = mw.html.create('div')
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
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._createCheckMarkOrCross(showIcon, iconType)
	local container = mw.html.create('div'):addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		return container:node(ICONS[iconType])
	end

	return container:node(ICONS.empty)
end

return CustomMatchSummary

---
-- @Liquipedia
-- wiki=halo
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local LINK_DATA = {
	faceit = {icon = 'File:FACEIT-icon.png', text = 'Match page on FACEIT'},
	halodatahive = {icon = 'File:Halo Data Hive allmode.png',text = 'Match page on Halo Data Hive'},
	headtohead = {
		icon = 'File:Match_Info_Halo_H2H.png',
		iconDark = 'File:Match_Info_Halo_H2H_darkmode.png',
		text = 'Head-to-head statistics'
	},
	stats = {icon = 'File:Match_Info_Stats.png', text = 'Match Statistics'},
}

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
	footer = MatchSummary.addVodsToFooter(match, footer)

	if
		match.opponents[1].type == Opponent.team and
		match.opponents[2].type == Opponent.team and
		match.opponents[1].name and
		match.opponents[2].name
	then
		local team1, team2 = string.gsub(match.opponents[1].name, ' ', '_'), string.gsub(match.opponents[2].name, ' ', '_')
		local buildQueryFormLink = function(form, template, arguments)
			return tostring(mw.uri.fullUrl('Special:RunQuery/' .. form,
				mw.uri.buildQueryString(Table.map(arguments, function(key, value) return template .. key, value end))
					.. '&_run'
			))
		end

		local headtoheadArgs = {
			['[team1]'] = team1,
			['[team2]'] = team2,
			['[games][is_list]'] = 1,
			['[tiers][is_list]'] = 1,
			['[fromdate][day]'] = '01',
			['[fromdate][month]'] = '01',
			['[fromdate][year]'] = string.sub(match.date,1,4)
		}

		match.links.headtohead = buildQueryFormLink('Head2head', 'Headtohead', headtoheadArgs)
	end

	return footer:addLinks(LINK_DATA, match.links)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default time, we have a date, so display the date
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

	-- casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	-- Add Match MVP(s)
	if match.extradata.mvp then
		local mvpData = match.extradata.mvp
		if not Table.isEmpty(mvpData) and mvpData.players then
			local mvp = MatchSummary.Mvp()
			for _, player in ipairs(mvpData.players) do
				mvp:addPlayer(player)
			end
			mvp:setPoints(mvpData.points)

			body:addRow(mvp)
		end

	end

	return body
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] or ''
	return mw.html.create('div'):wikitext(score)
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
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
		:wikitext(CustomMatchSummary._getMapDisplay(game))
		:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._addCheckmark(game.winner == 1))
		:node(CustomMatchSummary._gameScore(game, 1))

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._addCheckmark(game.winner == 2))

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

---@param game MatchGroupUtilGame
---@return string
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'
	if String.isNotEmpty(game.mode) then
		mapDisplay = MapModes.get{mode = game.mode} .. mapDisplay
	end
	return mapDisplay
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._addCheckmark(isWinner)
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

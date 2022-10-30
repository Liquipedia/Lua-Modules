---
-- @Liquipedia
-- wiki=halo
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local _EPOCH_TIME = '1970-01-01 00:00:00'
local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local htmlCreate = mw.html.create

local _GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
local _ICONS = {
	check = _GREEN_CHECK,
}

local _LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'LiveReport.png'},
	esl = {
		icon = 'File:ESL_2019_icon_lightmode.png',
		iconDark = 'File:ESL_2019_icon_darkmode.png',
		text = 'Match page on ESL'
	},
	faceit = {icon = 'File:FACEIT-icon.png', text = 'Match page on FACEIT'},
	halodatahive = {icon = 'File:Halo Data Hive allmode.png',text = 'Match page on Halo Data Hive'},
}

-- Custom Caster Class
local Casters = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-comment')
			:css('white-space','normal')
			:css('font-size','85%')
		self.casters = {}
	end
)

function Casters:addCaster(caster)
	if Logic.isNotEmpty(caster) then
		local nameDisplay = '[[' .. caster.name .. '|' .. caster.displayName .. ']]'
		if caster.flag then
			table.insert(self.casters, Flags.Icon(caster['flag']) .. ' ' .. nameDisplay)
		else
			table.insert(self.casters, nameDisplay)
		end
	end
	return self
end

function Casters:create()
	return self.root
		:wikitext('Caster' .. (#self.casters > 1 and 's' or '') .. ': ')
		:wikitext(table.concat(self.casters, #self.casters > 2 and ', ' or ' & '))
end

local CustomMatchSummary = {}

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()

	matchSummary:header(CustomMatchSummary._createHeader(match))
		:body(CustomMatchSummary._createBody(match))

	-- comment
	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	-- footer
	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	match.links.lrthread = match.lrthread
	match.links.vod = match.vod
	if not Table.isEmpty(vods) or not Table.isEmpty(match.links) then
		local footer = MatchSummary.Footer()

		-- Game Vods
		for index, vod in pairs(vods) do
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
				source = vod.url
			})
		end

		footer:addLinks(_LINK_DATA, match.links)

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createBody(match)
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

	-- casters
	if String.isNotEmpty(match.extradata.casters) then
		local casters = Json.parseIfString(match.extradata.casters)
		local casterRow = Casters()
		for _, caster in pairs(casters) do
			casterRow:addCaster(caster)
		end

		body:addRow(casterRow)
	end
	
	-- Add Match MVP(s)
	if (match.extradata or {}).mvp then
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
	if String.isNotEmpty(game.mode) then
		mapDisplay = MapModes.get{mode = game.mode} .. mapDisplay
	end
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

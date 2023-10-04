---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapTypeIcon = require('Module:MapType')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local WeaponIcon = require('Module:WeaponIcon')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base/temp', {requireDevIfEnabled = true})

local NUM_OPPONENTS = 2
local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local MAP_VETO_START = '<b>Start Map Veto</b>'
local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'
local TBD = 'TBD'
-- Normal links, from input/lpdb
local LINK_DATA = {
	vod = {icon = 'File:VOD Icon.png', text = 'Watch VOD'},
}
local NON_BREAKING_SPACE = '&nbsp;'

-- Map Veto Class
---@class SplatoonMapVeto: MatchSummaryRowInterface
---@operator call: SplatoonMapVeto
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

---@return self
function MapVeto:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','33%'):done()
		:tag('th'):css('width','34%'):wikitext('Map Veto'):done()
		:tag('th'):css('width','33%'):done()
	return self
end

---@param firstVeto number?
---@return self
function MapVeto:vetoStart(firstVeto)
	local textLeft
	local textCenter
	local textRight
	if firstVeto == 1 then
		textLeft = MAP_VETO_START
		textCenter = ARROW_LEFT
	elseif firstVeto == 2 then
		textCenter = ARROW_RIGHT
		textRight = MAP_VETO_START
	else return self end
	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft or ''):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight or ''):done()
	return self
end

---@param map string?
---@return string
function MapVeto._displayMap(map)
	if Logic.isEmpty(map) then
		map = TBD
	else
		map = '[[' .. map .. ']]'
	end

	return map
end

---@param map string?
---@return self
function MapVeto:addDecider(map)
	map = MapVeto._displayMap(map)
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
---@return self
function MapVeto:addRound(vetotype, map1, map2)
	map1 = MapVeto._displayMap(map1)
	map2 = MapVeto._displayMap(map2)

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
---@return self
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
---@return self
function MapVeto:addColumnVetoMap(row, map)
	row:tag('td'):wikitext(map):done()
	return self
end

---@return Html
function MapVeto:create()
	return self.root
end

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '490px'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer:addLinks(LINK_DATA, match.links)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.epochZero then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for _, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game)
		body:addRow(rowDisplay)
	end

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

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game)
	local row = MatchSummary.Row()

	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local extradata = game.extradata or {}
	local participants = game.participants or {}

	local numberOfWeapons = extradata.maximumpickindex

	local weaponsData = {}
	for opponentIndex = 1, NUM_OPPONENTS do
		weaponsData[opponentIndex] = {}
		for weaponIndex = 1, numberOfWeapons do
			local participantsKey = opponentIndex .. '_' .. weaponIndex
			weaponsData[opponentIndex][weaponIndex] = (participants[participantsKey] or {}).weapon or ''
		end
	end

	row:addClass('brkts-popup-body-game')
		:css('font-size', '90%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(CustomMatchSummary._opponentWeaponsDisplay{
		data = weaponsData[1],
		flip = false,
		game = game.game
	})
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(CustomMatchSummary._gameScore(game, 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('min-width', '156px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:node(mw.html.create('div')
			:css('margin', 'auto')
			:wikitext(CustomMatchSummary._getMapDisplay(game))
		)
	)
	row:addElement(CustomMatchSummary._gameScore(game, 2, true))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(CustomMatchSummary._opponentWeaponsDisplay{
		data = weaponsData[2],
		flip = true,
		game = game.game
	})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment:wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

---@param game MatchGroupUtilGame
---@return string
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = '[[' .. game.map .. ']]'

	if String.isNotEmpty(game.extradata.maptype) then
		mapDisplay = MapTypeIcon.display(game.extradata.maptype) .. NON_BREAKING_SPACE .. mapDisplay
	end

	return mapDisplay
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@param flip boolean?
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex, flip)
	return mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('min-width', '24px')
		:node(mw.html.create('div')
			:css('margin', 'auto')
			:wikitext(game.scores[opponentIndex] or '')
		)
end

---@param showIcon boolean?
---@return Html
function CustomMatchSummary._createCheckMark(showIcon)
	local container = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if Logic.readBool(showIcon) then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param props {data: string[], flip: boolean, game: string}
---@return Html
function CustomMatchSummary._opponentWeaponsDisplay(props)
	local flip = props.flip

	local displayElements = Array.map(props.data, function(weapon)
		return mw.html.create('div')
			:addClass('brkts-champion-icon')
			:node(WeaponIcon._getImage{
				weapon = weapon,
				game = props.game,
				class = 'brkts-champion-icon',
			})
	end)

	if flip then
		displayElements = Array.reverse(displayElements)
	end

	local display = mw.html.create('div')
		:addClass('brkts-popup-body-element-thumbs')
		:addClass('brkts-popup-body-element-thumbs-' .. (flip and 'right' or 'left'))

	for _, item in ipairs(displayElements) do
		display:node(item)
	end

	return display
end

return CustomMatchSummary

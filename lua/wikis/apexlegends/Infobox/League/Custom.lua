---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local Locale = Lua.import('Module:Locale')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local GAME_MODE = Lua.import('Module:GameMode', {loadData = true})
local EA_ICON = '&nbsp;[[File:EA icon.png|x15px|middle|link=Electronic Arts|'
	.. 'Tournament sponsored by Electronirc Arts & Respawn.]]'

---@class ApexlegendsLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.liquipediatiertype = league.args.liquipediatiertype or league.args.tiertype

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Teams', content = {args.team_number}},
			Cell{name = 'Number of players', content = {args.player_number}}
		)
	elseif id == 'gamesettings' then
		Array.appendWith(widgets,
			Cell{name = 'Game mode', content = {self.caller:_getGameMode()}},
			Cell{name = 'Platform', content = {self.caller:_getPlatform()}}
		)
	elseif id == 'liquipediatier' then
		if String.isNotEmpty(args.publishertier) then
			table.insert(widgets, 1, Cell{
				name = 'ALGS Circuit Tier',
				content = {'[[Apex Legends Global Series|' .. args.publishertier .. ']]'},
				classes = {'tournament-highlighted-bg'}
			})
		end
	elseif id == 'customcontent' then
		--maps
		if String.isNotEmpty(args.map1) then
			table.insert(widgets, Title{children = args.maptitle or 'Maps'})
			table.insert(widgets, Center{children = self.caller:_makeBasedListFromArgs('map')})
		elseif String.isNotEmpty(args['2map1']) then
			table.insert(widgets, Title{children = args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{children = self.caller:_makeBasedListFromArgs('2map')})
		end
	end
	return widgets
end


---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return String.isNotEmpty(args['ea-sponsored'])
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	return Logic.readBool(args['ea-sponsored']) and EA_ICON or ''
end

---@param base string
---@return string[]
function CustomLeague:_makeBasedListFromArgs(base)
	local firstArg = self.args[base .. '1']
	local foundArgs = {Page.makeInternalLink({}, firstArg)}
	local index = 2

	while String.isNotEmpty(self.args[base .. index]) do
		local currentArg = self.args[base .. index]
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(self:_createNoWrappingSpan(
				Page.makeInternalLink({}, currentArg)
			))
		)
		index = index + 1
	end

	return foundArgs
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.isIndividual = String.isNotEmpty(args.player_number) and 'true' or ''

	local publisherTier = string.lower(args.publishertier or '')
	self.data.publishertier = Logic.readBool(args.highlighted)
		or publisherTier ~= 'online' and Logic.nilIfEmpty(publisherTier)
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tiertype', args.liquipediatiertype)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)

	--Apexs specific vars
	Variables.varDefine('tournament_gamemode', string.lower(args.mode or ''))
	Variables.varDefine('tournament_series2', args.series2 or '')
	Variables.varDefine('tournament_publisher', args['ea-sponsored'] or '')
	Variables.varDefine('tournament_pro_circuit_tier', args.pctier or '')
	Variables.varDefine('tournament_individual', self.data.isIndividual)

	local regionData = Locale.formatLocations(args)
	Variables.varDefine('tournament_location_region', regionData.region1 or args.country)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = self.data.isIndividual
	lpdbData.extradata.platform = string.lower(args.platform or 'pc')

	--retrieve sponsors from args.sponsors if sponsorX, X=1,...,3, is empty
	if
		String.isEmpty(args.sponsor1) and
		String.isEmpty(args.sponsor2) and
		String.isEmpty(args.sponsor3) and
		String.isNotEmpty(args.sponsor)
	then
		local sponsors = Table.map(mw.text.split(args.sponsor, '<br>', true), function(index, value)
			return 'sponsor' .. index, value
		end)
		lpdbData.sponsors = mw.ext.LiquipediaDB.lpdb_create_json(sponsors)
	end

	return lpdbData
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

---@return string?
function CustomLeague:_getGameMode()
	local gameMode = self.args.mode
	if String.isEmpty(gameMode) then
		return nil
	end
	gameMode = string.lower(gameMode)
	return GAME_MODE[gameMode] or GAME_MODE['default']
end

---@return string?
function CustomLeague:_getPlatform()
	local platform = string.lower(self.args.platform or 'pc')
	if platform == 'pc' then
		return '[[PC Competitions|PC]][[Category:PC Competitions]]'
	elseif platform == 'console' then
		return '[[Console Competitions|Console]][[Category:Console Competitions]]'
	end
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.publishertier) then
		table.insert(categories, 'Apex Legends Global Series Tournaments')
	end
	if String.isNotEmpty(args.format) then
		table.insert(categories, args.format .. ' Format Tournaments')
	end
	if String.isNotEmpty(args.participants_number) then
		table.insert(categories, 'Individual Tournaments')
	end
	if args['ea-sponsored'] == 'true' then
		table.insert(categories, 'Electronic Arts Tournaments')
	end
	return categories
end

return CustomLeague

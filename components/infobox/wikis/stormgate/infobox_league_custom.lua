---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _league

local FALLBACK_DATE = '2999-99-99'

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
mw.logObject('here')
	local league = League(frame)
	_league = league
	_args = league.args

	_args.game = Game.name{game = _args.game}
	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype
	_args.raceBreakDown = RaceBreakdown.run(_args) or {}
	_args.player_number = _args.raceBreakDown.total
	_args.maps = CustomLeague._getMaps(_args)
	_args.number = Logic.isNumeric(_args.number) and string.format('%05i', tonumber(_args.number)) or nil
	--varDefault because it could have been set above the infobox via a template
	_args.cancelled = CustomLeague._checkCancelled(_args)
	_args.finished = CustomLeague._checkFinished(_args)

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

---@param args table
---@return boolean
function CustomLeague._checkCancelled(args)
	return args.status == 'cancelled' or Logic.readBool(_args.cancelled or Variables.varDefault('cancelled tournament'))
end

---@param args table
---@return boolean
function CustomLeague._checkFinished(args)
	if _args.cancelled then
		return true
	end
	if args.status == 'finished' then
		return true
	end

	local finished = Logic.readBoolOrNil(args.finished)
	if finished ~= nil then
		return finished
	end

	local queryDate = _league:_cleanDate(args.edate) or _league:_cleanDate(args.date) or FALLBACK_DATE
	if os.date('%Y-%m-%d') >= queryDate then
		local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
				.. 'AND [[opponentname::!TBD]] AND [[placement::1]]',
			query = 'date',
			order = 'date asc',
			limit = 1
		})
		if data and data[1] then
			return true
		end
	end

	return false
end

---@return WidgetInjector
function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		table.insert(widgets, Cell{name = 'Game version', content = {CustomLeague._getGameVersion(_args)}})
	elseif id == 'customcontent' then
		if _args.player_number and _args.player_number > 0 then
			Array.appendWith(widgets,
				Title{name = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {_args.raceBreakDown.total}},
				Breakdown{content = _args.raceBreakDown.display, classes = { 'infobox-center' }}
			)
		end

		--teams section
		if (tonumber(_args.team_number) or 0) > 0 then
			Array.appendWith(widgets,
				Title{name = 'Teams'},
				Cell{name = 'Number of teams', content = {_args.team_number}}
			)
		end

		--maps
		if String.isNotEmpty(_args.map1) then
			Array.appendWith(widgets,
				Title{name = 'Maps'},
				Center{content = {CustomLeague._mapsDisplay(_args.maps)}}
			)
		end
	end

	return widgets
end

---@param maps {link: string, displayname: string}[]?
---@return string?
function CustomLeague._mapsDisplay(maps)
	if not maps then return end

	return table.concat(
		Array.map(maps, function(mapData)
			return tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, mapData.displayname, mapData.link)
			))
		end),
		'&nbsp;• '
	)
end

---@param args table
---@return string
function CustomLeague._getGameVersion(args)
	local game = '[[' .. args.game .. ']]'

	if not args.patch then
		return game
	end

	local gameVersion = game .. '<br/>[[' .. args.patch .. ']]'
	if not args.epatch or args.epatch == args.patch then
		return gameVersion
	end

	return gameVersion .. ' &ndash; [[' .. args.epatch .. ']]'
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--override var to standardize its entries
	Variables.varDefine('tournament_game', args.game)

	--wiki specific vars
	Variables.varDefine('patch', args.patch)
	Variables.varDefine('epatch', args.epatch)
	Variables.varDefine('headtohead', tostring(Logic.nilOr(Logic.readBoolOrNil(args.headtohead), true)))
	Variables.varDefine('tournament_publishertier', tostring(Logic.readBool(args.publishertier)))
	Variables.varDefine('tournament_series_number', args.number)
	Variables.varDefine('tournament_maps', args.maps and Json.stringify(args.maps) or '')

	Variables.varDefine('tournament_series_number', tostring(args.cancelled))
end

---@param args table
---@return {link: string, displayname: string}[]?
function CustomLeague._getMaps(args)
	if String.isEmpty(args.map1) then
		return
	end
	local mapArgs = _league:getAllArgsForBase(args, 'map')

	return Table.map(mapArgs, function(mapIndex, map)
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(map),
			displayname = args['map' .. mapIndex .. 'display'] or map,
		}
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.game = args.game
	lpdbData.patch = args.patch
	lpdbData.endpatch = args.epatch or args.patch
	lpdbData.status = args.status
		or args.cancelled and 'cancelled'
		or args.finished and 'finished'
		or nil
	lpdbData.maps = args.maps and Json.stringify(args.maps) or nil
	lpdbData.next = CustomLeague:_getPageNameFromChronology(args.next)
	lpdbData.previous = CustomLeague:_getPageNameFromChronology(args.previous)

	lpdbData.extradata.seriesnumber = _args.number

	return lpdbData
end

---@param content string|Html|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

---@param item string?
---@return string?
function CustomLeague:_getPageNameFromChronology(item)
	if String.isEmpty(item) then
		return
	end
	---@cast item -nil

	return mw.ext.TeamLiquidIntegration.resolve_redirect(mw.text.split(item, '|')[1])
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publishertier)
end

return CustomLeague

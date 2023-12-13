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

local CANCELLED = 'cancelled'
local FINISHED = 'finished'

local _args
local _league

local FALLBACK_DATE = '2999-99-99'

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = league.args

	_args.game = Game.name{game = _args.game}
	_args.raceBreakDown = RaceBreakdown.run(_args) or {}
	_args.player_number = _args.raceBreakDown.total
	_args.maps = CustomLeague._getMaps(_args)
	_args.number = Logic.isNumeric(_args.number) and string.format('%05i', tonumber(_args.number)) or nil
	--varDefault because it could have been set above the infobox via a template
	_args.status = CustomLeague._getStatus(_args)

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

---@param args table
---@return string?
function CustomLeague._getStatus(args)
	local status = args.status or Variables.varDefault('tournament_status')
	if Logic.isNotEmpty(status) then
		---@cast status -nil
		return status:lower()
	end

	if Logic.readBool(_args.cancelled) then
		return CANCELLED
	end

	if CustomLeague._isFinished(args) then
		return FINISHED
	end
end

---@param args table
---@return boolean
function CustomLeague._isFinished(args)
	local finished = Logic.readBoolOrNil(args.finished)
	if finished ~= nil then
		return finished
	end

	local queryDate = _league:_cleanDate(args.edate) or _league:_cleanDate(args.date) or FALLBACK_DATE

	if os.date('%Y-%m-%d') < queryDate then
		return false
	end

	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
			.. 'AND [[opponentname::!TBD]] AND [[placement::1]]',
		query = 'date',
		order = 'date asc',
		limit = 1
	})[1] ~= nil
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
		table.insert(widgets, Cell{name = 'Game Version', content = {CustomLeague._getGameVersion(_args)}})
	elseif id == 'customcontent' then
		if _args.player_number and _args.player_number > 0 then
			Array.appendWith(widgets,
				Title{name = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {_args.raceBreakDown.total}},
				Breakdown{content = _args.raceBreakDown.display, classes = { 'infobox-center' }}
			)
		end

		--teams section
		if Logic.isNumeric(_args.team_number) and tonumber(_args.team_number) > 0 then
			Array.appendWith(widgets,
				Title{name = 'Teams'},
				Cell{name = 'Number of Teams', content = {_args.team_number}}
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
---@return string?
function CustomLeague._getGameVersion(args)
	if not args.patch then
		return
	end

	local gameVersion = '[[' .. args.patch .. ']]'
	if not args.epatch or args.epatch == args.patch then
		return gameVersion
	end

	return gameVersion .. ' &ndash; [[' .. args.epatch .. ']]'
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)

	--wiki specific vars
	Variables.varDefine('patch', args.patch)
	Variables.varDefine('epatch', args.epatch)
	Variables.varDefine('tournament_publishertier', tostring(Logic.readBool(args.publishertier)))
	Variables.varDefine('tournament_maps', args.maps and Json.stringify(args.maps) or '')
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
	lpdbData.status = args.status
	lpdbData.maps = args.maps and Json.stringify(args.maps) or nil

	lpdbData.extradata.seriesnumber = _args.number

	return lpdbData
end

---@param content string|Html|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publishertier)
end

return CustomLeague

---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Autopatch = require('Module:Automated Patch')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local SeriesTotalPrize = require('Module:SeriesTotalPrize')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local GAME_MOD = 'mod'
local GAME_LOTV = Game.toIdentifier{game = 'lotv'}
local TODAY = os.date('%Y-%m-%d', os.time())

local CustomInjector = Class.new(Injector)

---@class Starcraft2SeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	local args = series.args

	args.game = (args.game or ''):lower() == GAME_MOD and GAME_MOD or Game.toIdentifier{game = args.game}

	args.liquipediatiertype = args.liquipediatiertype or args.tiertype
	args.liquipediatier = args.liquipediatier or args.tier

	series:_addCustomVariables()

	return series:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'totalprizepool' then
		if Logic.readBoolOrNil(args.prizepooltot) == false then return {} end
		return {
			Cell{name = 'Cumulative Prize Pool', content = {self.caller:_displaySeriesPrizepools()}},
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game version', content = {self.caller:_getGameVersion(args.game, args.patch)}},
			Cell{name = 'Server', content = {args.server}},
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Format', content = {args.format}}
		)
	end

	return widgets
end

---@return string?
function CustomSeries:_displaySeriesPrizepools()
	local args = self.args
	local seriesTotalPrizeInput = Json.parseIfString(args.prizepooltot or '{}')
	local series = seriesTotalPrizeInput.series or args.series or self.pagename

	return SeriesTotalPrize._get{
		series = series,
		limit = seriesTotalPrizeInput.limit or args.limit,
		offset = seriesTotalPrizeInput.offset or args.offset,
		external = seriesTotalPrizeInput.external or args.external,
		onlytotal = seriesTotalPrizeInput.onlytotal or args.onlytotal,
	}
end

---@param game string?
---@param patch string?
---@return string
function CustomSeries:_getGameVersion(game, patch)
	local args = self.args

	local shouldUseAutoPatch = Logic.readBool(args.autopatch or true)
	local modName = args.modname
	local betaPrefix = String.isNotEmpty(args.beta) and 'Beta ' or ''
	local endPatch = args.epatch
	local startDate = args.sdate
	local endDate = args.edate

	local gameVersion
	if game == GAME_MOD then
		gameVersion = modName or 'Mod'
	else
		gameVersion = '[[' .. Game.name{game = game} .. ']]' ..
			'[[Category:' .. betaPrefix .. Game.abbreviation{game = game} .. ' Competitions]]'
	end

	if game == GAME_LOTV and shouldUseAutoPatch then
		if String.isEmpty(patch) then
			patch = 'Patch ' .. (Autopatch._main({CustomSeries._retrievePatchDate(startDate)}) or '')
		end
		if String.isEmpty(endPatch) then
			endPatch = 'Patch ' .. (Autopatch._main({CustomSeries._retrievePatchDate(endDate)}) or '')
		end
	elseif String.isEmpty(endPatch) then
		endPatch = patch
	end

	local patchDisplay = betaPrefix

	if String.isNotEmpty(patch) then
		patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']]'
		if patch ~= endPatch then
			patchDisplay = patchDisplay .. ' &ndash; [[' .. endPatch .. ']]'
		end
	end

	--set patch variables
	Variables.varDefine('patch', patch)
	Variables.varDefine('epatch', endPatch)

	return gameVersion .. patchDisplay
end

---@param dateEntry string?
---@return string|osdate
function CustomSeries._retrievePatchDate(dateEntry)
	return String.isNotEmpty(dateEntry) ---@cast dateEntry -nil
		and dateEntry:lower() ~= 'tbd'
		and dateEntry:lower() ~= 'tba'
		and dateEntry or TODAY
end

function CustomSeries:_addCustomVariables()
	local args = self.args

	if
		(not Namespace.isMain()) or
		Logic.readBool(args.disable_lpdb) or
		Logic.readBool(args.disable_storage)
	then
		Variables.varDefine('disable_LPDB_storage', 'true')
	else
		--needed for e.g. External Cups Lists
		local name = args.name or self.pagename
		Variables.varDefine('tournament_publishertier', tostring(Logic.readBool(args.highlighted)))
		Variables.varDefine('headtohead', args.headtohead or '')
		local tier, tierType = Tier.toValue(args.liquipediatier, args.liquipediatiertype)
		Variables.varDefine('tournament_liquipediatier', tier or '')
		Variables.varDefine('tournament_liquipediatiertype', tierType or '')
		Variables.varDefine('tournament_mode', args.mode or '1v1')
		Variables.varDefine('tournament_tickername', args.tickername or name)
		Variables.varDefine('tournament_shortname', args.shortname or '')
		Variables.varDefine('tournament_name', name)
		Variables.varDefine('tournament_series', self.pagename)
		Variables.varDefine('tournament_parent', (args.parent or self.pagename):gsub(' ', '_'))
		Variables.varDefine('tournament_game', args.game)
		Variables.varDefine('tournament_type', args.type or '')
		CustomSeries._setDateMatchVar(args.date, args.edate, args.sdate)
	end
end

---@param lpdbData table
---@return table
function CustomSeries:addToLpdb(lpdbData)
	Variables.varDefine('tournament_icon', lpdbData.icon)
	Variables.varDefine('tournament_icon_dark', lpdbData.icondark)
	return lpdbData
end

---@param date string?
---@param edate string?
---@param sdate string?
function CustomSeries._setDateMatchVar(date, edate, sdate)
	local endDate = CustomSeries._validDateOr(date, edate, sdate) or ''
	local startDate = CustomSeries._validDateOr(date, sdate, edate) or ''

	Variables.varDefine('tournament_enddate', endDate)
	Variables.varDefine('tournament_startdate', startDate)
end

---@param ... string
---@return string?
function CustomSeries._validDateOr(...)
	local regexString = '%d%d%d%d%-%d%d%-%d%d' --(i.e. YYYY-MM-DD)

	for _, input in Table.iter.spairs({...}) do
		local dateString = string.match(input, regexString)
		if dateString then
			return dateString
		end
	end
end

return CustomSeries

---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell

local GAME_MOD = 'mod'
local GAME_LOTV = Game.name{game = 'lotv'}
local TODAY = os.date('%Y-%m-%d', os.time())

local CustomInjector = Class.new(Injector)

local CustomSeries = {}

local _args
local _series

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args
	_series = series

	_args.game = _args.game == GAME_MOD and GAME_MOD or Game.name{game = _args.game}

	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype
	_args.liquipediatier = _args.liquipediatier or _args.tier

	series.addToLpdb = CustomSeries.addToLpdb
	series.createWidgetInjector = CustomSeries.createWidgetInjector

	return series:createInfobox()
end

---@return WidgetInjector
function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Game version',
		content = {
			CustomSeries._getGameVersion(_args.game, _args.patch)
		}
	})
	table.insert(widgets, Cell{
		name = 'Server',
		content = {_args.server}
	})
	table.insert(widgets, Cell{
		name = 'Type',
		content = {_args.type}
	})
	table.insert(widgets, Cell{
		name = 'Format',
		content = {_args.format}
	})
	table.insert(widgets, Builder{
		builder = function()
			if _args.prizepooltot ~= 'false' then
				return {
					Cell{
						name = 'Total prize money',
						content = {CustomSeries._getSeriesPrizepools()}
					}
				}
			end
		end
	})

	CustomSeries._addCustomVariables()

	return widgets
end

---@return string?
function CustomSeries._getSeriesPrizepools()
	local seriesTotalPrizeInput = Json.parseIfString(_args.prizepooltot or '{}')
	local series = seriesTotalPrizeInput.series or _args.series or mw.title.getCurrentTitle().text

	return SeriesTotalPrize._get{
		series = series,
		limit = seriesTotalPrizeInput.limit or _args.limit,
		offset = seriesTotalPrizeInput.offset or _args.offset,
		external = seriesTotalPrizeInput.external or _args.external,
		onlytotal = seriesTotalPrizeInput.onlytotal or _args.onlytotal,
	}
end

---@param game string?
---@param patch string?
---@return string
function CustomSeries._getGameVersion(game, patch)
	local shouldUseAutoPatch = Logic.readBool(_args.autopatch or true)
	local modName = _args.modname
	local betaPrefix = String.isNotEmpty(_args.beta) and 'Beta ' or ''
	local endPatch = _args.epatch
	local startDate = _args.sdate
	local endDate = _args.edate

	local gameVersion
	if game == GAME_MOD then
		gameVersion = modName or 'Mod'
	else
		gameVersion = '[[' .. game .. ']]' ..
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

function CustomSeries._addCustomVariables()
	if
		(not Namespace.isMain()) or
		Logic.readBool(_args.disable_lpdb) or
		Logic.readBool(_args.disable_storage)
	then
		Variables.varDefine('disable_LPDB_storage', 'true')
	else
		--needed for e.g. External Cups Lists
		local name = _args.name or _series.pagename
		Variables.varDefine('tournament_publishertier', tostring(Logic.readBool(_args.featured)))
		Variables.varDefine('headtohead', _args.headtohead or '')
		local tier, tierType = Tier.toValue(_args.liquipediatier, _args.liquipediatiertype)
		Variables.varDefine('tournament_liquipediatier', tier or '')
		Variables.varDefine('tournament_liquipediatiertype', tierType or '')
		Variables.varDefine('tournament_mode', _args.mode or '1v1')
		Variables.varDefine('tournament_tickername', _args.tickername or name)
		Variables.varDefine('tournament_shortname', _args.shortname or '')
		Variables.varDefine('tournament_name', name)
		Variables.varDefine('tournament_series', _series.pagename)
		Variables.varDefine('tournament_parent', (_args.parent or _series.pagename):gsub(' ', '_'))
		Variables.varDefine('tournament_game', _args.game)
		Variables.varDefine('tournament_type', _args.type or '')
		CustomSeries._setDateMatchVar(_args.date, _args.edate, _args.sdate)
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

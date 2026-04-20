---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local PatchAuto = Lua.import('Module:Infobox/Extension/PatchAuto')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local SeriesTotalPrize = Lua.import('Module:SeriesTotalPrize')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')
local Variables = Lua.import('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Link = Lua.import('Module:Widget/Basic/Link')
local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local GAME_MOD = 'mod'
local GAME_LOTV = Game.toIdentifier{game = 'lotv'}
local TODAY = os.date('%Y-%m-%d', os.time())

---@class Starcraft2SeriesInfoboxWidgetInjector: WidgetInjector
---@field caller Starcraft2SeriesInfobox
local CustomInjector = Class.new(Injector)

---@class Starcraft2SeriesInfobox: SeriesInfobox
---@operator call(Frame): Starcraft2SeriesInfobox
---@field patchData {patch: string?, endPatch: string?, patchDisplay: string?, endPatchDisplay: string?}
local CustomSeries = Class.new(Series)

---@param frame Frame
---@return Widget
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	local args = series.args

	args.game = (args.game or ''):lower() == GAME_MOD and GAME_MOD or Game.toIdentifier{game = args.game}

	series.patchData = series:_computePatch()

	args.liquipediatiertype = args.liquipediatiertype or args.tiertype
	args.liquipediatier = args.liquipediatier or args.tier

	series:_addCustomVariables()

	return series:createInfobox()
end

---@private
---@return {patch: string?, endPatch: string?, patchDisplay: string?, endPatchDisplay: string?}
function CustomSeries:_computePatch()
	local args = self.args

	local prefixPatch = function(patch)
		if not patch then return end
		return 'Patch ' .. patch:gsub(' ', '_')
	end
	local patch = prefixPatch(args.patch)
	local endPatch = prefixPatch(args.epatch)

	if args.game ~= GAME_LOTV or not Logic.nilOr(Logic.readBoolOrNil(args.autopatch), true) then
		return {
			patch = patch,
			endPatch = endPatch,
		}
	end

	return PatchAuto.run(
		{
			patch = patch,
			endPatch = endPatch,
			startDate = CustomSeries._validDateOr(args.date, args.sdate),
			endDate = CustomSeries._validDateOr(args.date, args.edate)
		},
		{
			patch_display = patch,
			epatch_display = endPatch,
		}
	)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'totalprizepool' then
		if Logic.readBoolOrNil(args.prizepooltot) == false then return {} end
		return {
			Cell{name = 'Cumulative Prize Pool', children = {self.caller:_displaySeriesPrizepools()}},
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game version', children = self.caller:_getGameVersion()},
			Cell{name = 'Server', children = {args.server}},
			Cell{name = 'Type', children = {args.type}},
			Cell{name = 'Format', children = {args.format}}
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

---@return Renderable[]
function CustomSeries:_getGameVersion()
	local args = self.args

	local betaPrefix = String.isNotEmpty(args.beta) and 'Beta ' or ''

	local gameDisplay = args.game == GAME_MOD and (args.modname or 'Mod')
		or Link{link = Game.name{game = args.game}}

	local patchData = self.patchData
	local patch = patchData.patch
	local endPatch = patchData.endPatch

	local patches = Array.map(Array.map({
		Link{link = patch, children = patchData.patchDisplay},
		Link{link = endPatch ~= patch and patch and endPatch or nil, children = patchData.endPatchDisplay}
	}, tostring), Logic.nilIfEmpty)

	local patchDisplay = betaPrefix .. table.concat(patches, ' &ndash; ')

	return {gameDisplay, patchDisplay}
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
		--set patch variables
		Variables.varDefine('patch', self.patchData.patch)
		Variables.varDefine('epatch', self.patchData.endPatch)
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

---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class RainbowsixLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local DEFAULT_TIERTYPE = 'General'
local DEFAULT_PLATFORM = 'PC'
local PLATFORM_ALIAS = {
	console = 'Console',
	pc = 'PC',
	xbox = 'Xbox',
	xone = 'Xbox',
	['xbox one'] = 'Xbox',
	one = 'Xbox',
	playstation = 'Playstation',
	ps = 'Playstation',
	ps4 = 'Playstation',
	mobile = 'Mobile',
}

local UBISOFT_TIERS = {
	si = 'Six Invitational',
	pl = 'Pro League',
	cl = 'Challenger League',
	national = 'National',
	major = 'Major',
	minor = 'Minor',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
		Cell{name = 'Teams', content = {(args.team_number or '') .. (args.team_slots and ('/' .. args.team_slots) or '')}},
		Cell{name = 'Game', content = {Game.name{game = args.game}}},
		Cell{name = 'Platform', content = {caller:_createPlatformCell(args)}},
		Cell{name = 'Players', content = {args.player_number}}
	)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(caller:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(caller:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'liquipediatier' then
		if caller.data.publishertier then
			table.insert(widgets,
				Cell{
					name = 'Ubisoft Tier',
					content = {'[[' .. UBISOFT_TIERS[caller.data.publishertier] .. ']]'},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''
	lpdbData.extradata.startdatetext = self:_standardiseRawDate(args.sdate or args.date)
	lpdbData.extradata.enddatetext = self:_standardiseRawDate(args.edate or args.date)

	return lpdbData
end

---@param publishertier string?
---@return string?
function CustomLeague:_validPublisherTier(publishertier)
	return UBISOFT_TIERS[string.lower(publishertier or '')]
end

---@param dateString string
---@return string
function CustomLeague:_standardiseRawDate(dateString)
	-- Length 7 = YYYY-MM
	-- Length 10 = YYYY-MM-??
	if String.isEmpty(dateString) or (#dateString ~= 7 and #dateString ~= 10) then
		return ''
	end

	if #dateString == 7 then
		dateString = dateString .. '-??'
	end
	dateString = dateString:gsub('%-XX', '-??')
	return dateString
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.liquipediatiertype = self.data.liquipediatiertype or DEFAULT_TIERTYPE
	self.data.publishertier = self:_validPublisherTier(args.publishertier) and args.publishertier:lower()
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', self.data.liquipediatiertype)
	Variables.varDefine('tournament_prizepool', args.prizepool or '')

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local game = Game.name{game = args.game}
	local platform = self:_platformLookup(args.platform)

	return {
		game and (game .. ' Competitions') or 'Tournaments without game version',
		platform and (platform .. ' Tournaments') or nil,
	}
end

---@param platform string?
---@return string?
function CustomLeague:_platformLookup(platform)
	if String.isEmpty(platform) then
		platform = DEFAULT_PLATFORM
	end
	---@cast platform -nil

	return PLATFORM_ALIAS[platform:lower()]
end

---@param args table
---@return string?
function CustomLeague:_createPlatformCell(args)
	local platform = self:_platformLookup(args.platform)

	if String.isNotEmpty(platform) then
		return PageLink.makeInternalLink({}, platform, ':Category:'..platform)
	else
		return nil
	end
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague

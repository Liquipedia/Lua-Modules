---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class ValorantLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local VALID_PUBLISHERTIERS = {
	'highlighted',
	'sponsored',
}

local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Tournament supported by Riot Games]]'

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.liquipediatier = Tier.toNumber(league.args.liquipediatier)

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = (args.individual or args.player_number) and '1v1' or 'team'

	-- female as a temp alias to bot the old input over
	self.data.gameChangers = Logic.readBool(args.gc)

	local publisherTier = (args.publishertier or ''):lower()
	self.data.publishertier = Table.includes(VALID_PUBLISHERTIERS, publisherTier) and publisherTier
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Teams', content = {(args.team_number or '') .. (args.team_slots and ('/' .. args.team_slots) or '')}},
			Cell{name = 'Players', content = {args.player_number}}
		)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(self.caller:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(self.caller:_createNoWrappingSpan(
					Page.makeInternalLink({}, map, map .. game)
				)))
			end
			table.sort(maps)
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Patch',
			content = {self.caller:_createPatchCell(args)}
		})
	end

	return widgets
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {}

	if self.data.gameChangers then
		table.insert(categories, 'Game Changers Tournaments')
	end

	return categories
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.region = Template.safeExpand(mw.getCurrentFrame(), 'Template:Player region', {args.country})
	lpdbData.extradata.startdate_raw = args.sdate or args.date
	lpdbData.extradata.enddate_raw = args.edate or args.date
	lpdbData.extradata.gamechangers = tostring(self.data.gameChangers)

	return lpdbData
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	if self.data.publishertier then
		return ' ' .. RIOT_ICON
	end
	return ''
end

---@param args table
---@return string?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end
	local content

	if String.isEmpty(args.epatch) then
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]'
	else
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]' .. ' &ndash; ' ..
		'[[Patch ' .. args.epatch .. '|'.. args.epatch .. ']]'
	end

	return content
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Wiki Custom
	Variables.varDefine('gamechangers', tostring(self.data.gameChangers))
	Variables.varDefine('tournament_riot_premier', args.riotpremier and 'true' or '')
	Variables.varDefine('patch', args.patch or '')

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', self.data.tickerName)
	Variables.varDefine('tournament_tier', self.data.liquipediatier)
	Variables.varDefine('tournament_tiertype', self.data.liquipediatiertype)

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague

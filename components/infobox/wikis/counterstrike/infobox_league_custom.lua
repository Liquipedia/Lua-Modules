---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Currency = Lua.import('Module:Currency')
local Game = Lua.import('Module:Game')
local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool')
local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local Tier = Lua.import('Module:Tier/Custom')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class CounterstrikeLeagueInfobox: InfoboxLeague
---@field gameData table
---@field valveTier {meta: string, name: string, link: string}?
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local ESL_PRO_TIERS_SIZE = '40x40px'
local ESL_PRO_TIERS = {
	['national challenger'] = {
		icon = 'ESL Pro Tour Challenger.png',
		name = 'National Champ.',
		link = 'ESL National Championships'
	},
	['international challenger'] = {
		icon = 'ESL Pro Tour Challenger.png',
		name = 'Challenger',
		link = 'ESL Pro Tour'
	},
	['regional challenger'] = {
		icon = 'ESL Pro Tour Challenger.png',
		name = 'Regional Challenger',
		link = 'ESL/Pro Tour'
	},
	['masters'] = {
		icon = 'ESL Pro Tour Masters.png',
		name = 'Masters',
		link = 'ESL/Pro Tour'
	},
	['regional masters'] = {
		icon = 'ESL Pro Tour Masters.png',
		name = 'Regional Masters',
		link = 'ESL/Pro Tour'
	},
	['masters championship'] = {
		icon = 'ESL Pro Tour Masters Championship.png',
		name = 'Masters Champ.',
		link = 'ESL Pro Tour'
	},
	['major championship'] = {
		icon = 'Valve csgo tournament icon.png',
		name = 'Major Championship',
		link = 'Majors'
	},
}
ESL_PRO_TIERS['national championship'] = ESL_PRO_TIERS['national challenger']
ESL_PRO_TIERS['challenger'] = ESL_PRO_TIERS['international challenger']

local VALVE_TIERS = {
	['major'] = {meta = 'Major Championship', name = 'Major Championship', link = 'Majors'},
	['major qualifier'] = {meta = 'Major Championship main qualifier', name = 'Major Qualifier', link = 'Majors'},
	['minor'] = {meta = 'Regional Minor Championship', name = 'Minor Championship', link = 'Minors'},
	['rmr event'] = {meta = 'Regional Major Rankings event', name = 'RMR Event', link = 'Regional Major Rankings'},
	['tier 1'] = {meta = 'Valve Tier 1 event', name = 'Tier 1', link = 'Valve Tier 1 Events'},
	['tier 1 qualifier'] = {meta = 'Valve Tier 1 qualifier', name = 'Tier 1 Qualifier', link = 'Valve Tier 1 Events'},
	['tier 2'] = {meta = 'Valve Tier 2 event', name = 'Tier 2', link = 'Valve Tier 2 Events'},
	['tier 2 qualifier'] = {meta = 'Valve Tier 2 qualifier', name = 'Tier 2 Qualifier', link = 'Valve Tier 2 Events'},
	['wildcard'] = {meta = 'Valve Wildcard qualifier', name = 'Wildcard', link = 'Valve Wildcard Events'},
}

local RESTRICTIONS = {
	['female'] = {
		name = 'Female Players Only',
		link = 'Female Tournaments',
		data = 'female',
	},
	['academy'] = {
		name = 'Academy Teams Only',
		link = 'Academy Tournaments',
		data = 'academy',
	}
}

local DATE_TBA = 'tba'

local MODE_1v1 = '1v1'
local MODE_TEAM = 'team'

local PRIZE_POOL_ROUND_PRECISION = 2

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.publisherdescription = 'metadesc-valve'
	league.args.liquipediatier = Tier.toNumber(league.args.liquipediatier)
	league.args.currencyDispPrecision = PRIZE_POOL_ROUND_PRECISION
	league.gameData = Game.raw{game = league.args.game, useDefault = false}
	league.valveTier = VALVE_TIERS[(league.args.valvetier or ''):lower()]

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = (self.valveTier or {}).name
	if String.isNotEmpty(args.localcurrency) and String.isNotEmpty(args.prizepool) then
		local currency = string.upper(args.localcurrency)
		local prize = InfoboxPrizePool._cleanValue(args.prizepool)
		self.data.localPrizePool = Currency.display(currency, prize, {
				formatValue = true,
				formatPrecision = PRIZE_POOL_ROUND_PRECISION
			})
	end
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
		Cell{name = 'Teams', content = {(args.team_number or '') .. (args.team_slots and ('/' .. args.team_slots) or '')}},
		Cell{name = 'Players', content = {args.player_number}},
		Cell{name = 'Restrictions', content = self.caller:createRestrictionsCell(args.restrictions)}
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
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'liquipediatier' then
		table.insert(
			widgets,
			Cell{
				name = '[[File:ESL 2019 icon.png|20x20px|link=|ESL|alt=ESL]] Pro Tour Tier',
				content = {self.caller:_createEslProTierCell(args.eslprotier)},
				classes = {'infobox-icon-small'}
			}
		)
		table.insert(
			widgets,
			Cell{
				name = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox') .. ' Tier',
				content = {self.caller:_createValveTierCell()},
				classes = {'valvepremier-highlighted'}
			}
		)
	elseif id == 'gamesettings' then
		return {
			Cell{
				name = 'Game',
				content = {self.caller:_createGameCell(args)}
			}
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local gameData = Table.isNotEmpty(self.gameData) and self.gameData
	local categories = {
		gameData and ((gameData.abbreviation or gameData.name) .. ' Tournaments') or 'Tournaments without game version',
	}

	if not Logic.readBool(args.cancelled) and
		(String.isNotEmpty(args.prizepool) and args.prizepool ~= 'Unknown') and
		String.isEmpty(args.prizepoolusd) then
		table.insert(categories, 'Infobox league lacking prizepoolusd')
	end

	if String.isNotEmpty(args.prizepool) and String.isEmpty(args.localcurrency) then
		table.insert(categories, 'Infobox league lacking localcurrency')
	end

	if String.isEmpty(args.country) then
		table.insert(categories, 'Tournaments without location')
	end

	if String.isNotEmpty(args.sort_date) then
		table.insert(categories, 'Tournaments with custom sort date')
	end

	if String.isNotEmpty(args.eslprotier) then
		table.insert(categories, 'ESL Pro Tour Tournaments')
	end

	if self.valveTier then
		table.insert(categories, 'Valve Sponsored Tournaments')
	end

	if String.isNotEmpty(args.restrictions) then
		Array.extendWith(categories, Array.map(CustomLeague.getRestrictions(args.restrictions),
				function(res) return res.link end))
	end

	return categories
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args.cstrikemajor) then
		return ' [[File:cstrike-icon.png|x16px|link=Counter-Strike Majors|Counter-Strike Major]]'
	end
	return ''
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	if self.valveTier then
		Variables.varDefine('metadesc-valve', self.valveTier.meta)
	end

	-- Legacy vars
	Variables.varDefine('tournament_short_name', args.shortname)
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_icon_darkmode', self.data.iconDark)

	if String.isNotEmpty(args.date) and args.date:lower() ~= DATE_TBA then
		Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	end

	if String.isNotEmpty(args.sdate) and args.sdate:lower() ~= DATE_TBA then
		Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
		Variables.varDefine('tournament_sdate', ReferenceCleaner.clean(args.sdate or args.date))
	end

	if String.isNotEmpty(args.edate) and args.edate:lower() ~= DATE_TBA then
		local cleandDate = ReferenceCleaner.clean(args.edate or args.date)
		Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))
		Variables.varDefine('tournament_date', cleandDate)
		Variables.varDefine('tournament_edate', cleandDate)
	end

	-- Legacy tier vars
	local tierName = Tier.toName(args.liquipediatier)
	Variables.varDefine('tournament_tier', tierName) -- Stores as X-tier, not the integer

	-- Wiki specific vars
	local valveTier = (self.valveTier or {}).name
	Variables.varDefine('tournament_valve_tier', valveTier)
	Variables.varDefine('tournament_publishertier', valveTier)
	Variables.varDefine('tournament_cstrike_major', args.cstrikemajor)

	Variables.varDefine('tournament_mode',
		(String.isNotEmpty(args.individual) or String.isNotEmpty(args.player_number))
		and MODE_1v1 or MODE_TEAM
	)
	Variables.varDefine('no team result',
		(args.series == 'ESEA Rank S' or
			args.series == 'FACEIT Pro League' or
			args.series == 'Danish Pro League' or
			args.series == 'Swedish Pro League') and 'true' or 'false')

	-- local Prize Pool var
	Variables.varDefine('prizepoollocal', self.data.localPrizePool)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	if Logic.readBool(args.charity) or Logic.readBool(args.noprize) then
		lpdbData.prizepool = 0
	end

	lpdbData.maps = table.concat(self:getAllArgsForBase(args, 'map'), ';')
	lpdbData.sortdate = args.sort_date or lpdbData.enddate

	lpdbData.extradata.prizepoollocal = self.data.localPrizePool
	lpdbData.extradata.startdate_raw = args.sdate or args.date
	lpdbData.extradata.enddate_raw = args.edate or args.date
	lpdbData.extradata.shortname2 = args.shortname2

	Array.forEach(CustomLeague.getRestrictions(args.restrictions),
		function(res) lpdbData.extradata['restriction_' .. res.data] = 1 end)

	-- Extradata variable
	Variables.varDefine('tournament_extradata', Json.stringify(lpdbData.extradata))

	return lpdbData
end

---@param args table
---@return string?
function CustomLeague:_createGameCell(args)
	if Table.isEmpty(self.gameData) and String.isEmpty(args.patch) then
		return nil
	end

	local content = ''

	if Table.isNotEmpty(self.gameData) then
		content = content .. Page.makeInternalLink({}, self.gameData.name, self.gameData.link)
	end

	if String.isEmpty(args.epatch) and String.isNotEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	elseif String.isNotEmpty(args.epatch) then
		content = content .. '<br> [[' .. args.patch .. ']]' .. '&ndash;' .. '[[' .. args.epatch .. ']]'
	end

	return content
end

---@param restrictions string?
---@return {name: string, data: string, link: string}[]
function CustomLeague.getRestrictions(restrictions)
	if String.isEmpty(restrictions) then
		return {}
	end
	---@cast restrictions -nil

	return Array.map(mw.text.split(restrictions, ','),
		function(restriction) return RESTRICTIONS[mw.text.trim(restriction)] end)
end

---@param restrictions string?
---@return string[]
function CustomLeague:createRestrictionsCell(restrictions)
	local restrictionData = CustomLeague.getRestrictions(restrictions)
	return Array.map(restrictionData, function(res) return self:createLink(res.link, res.name) end)
end

---@param eslProTier string?
---@return string?
function CustomLeague:_createEslProTierCell(eslProTier)
	local tierData = ESL_PRO_TIERS[(eslProTier or ''):lower()]

	if tierData then
		return '[[File:'.. tierData.icon ..'|' .. ESL_PRO_TIERS_SIZE .. '|link=' .. tierData.link ..
			'|' .. tierData.name .. ']] ' .. tierData.name
	end
end

---@return string?
function CustomLeague:_createValveTierCell()
	if self.valveTier then
		return '[[' .. self.valveTier.link .. '|' .. self.valveTier.name .. ']]'
	end
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague

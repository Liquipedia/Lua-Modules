---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Set = require('Module:Set')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local YearsActive = require('Module:YearsActive')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local Player = Lua.import('Module:Infobox/Person')

local CURRENT_YEAR = tonumber(os.date('%Y'))

local Injector = Lua.import('Module:Widget/Injector')
local Widgets = Lua.import('Module:Widget/All')

local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class StormgateInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{
		player = player.pagename,
		addlpdbdata = player:shouldStoreData(player.args),
	}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local currentYearEarnings = caller.earningsPerYear[CURRENT_YEAR] or 0

		return {
			Cell{
				name = 'Approx. Winnings ' .. CURRENT_YEAR,
				content = {currentYearEarnings > 0 and ('$' .. mw.getContentLanguage():formatNum(currentYearEarnings)) or nil}
			},
			Cell{
				name = Abbreviation.make{text = 'Years Active', title = 'Years active as a player'},
				content = {YearsActive.display({player = caller.pagename})
			}
			},
			Cell{
				name = Abbreviation.make{text = 'Years Active (caster)', title = 'Years active as a caster'},
				content = {caller:_getActiveCasterYears()}
			},
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Faction', content = {caller:getFactionData(args.faction or 'unknown')}}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		local achievements = Achievements.player{
			noTemplate = true,
			onlyForFirstPrizePoolOfPage = true,
			player = caller.pagename,
			onlySolo = true,
		}
		if not achievements then return {} end

		return {
			Title{children = 'Achievements'},
			Center{children = {achievements}},
		}
	elseif id == 'history' and string.match(args.retired or '', '%d%d%d%d') then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end

	return widgets
end

---@return string|nil
function CustomPlayer:_getActiveCasterYears()
	if not self:shouldStoreData(self.args) then return end

	local queryData = mw.ext.LiquipediaDB.lpdb('broadcasters', {
		query = 'year::date',
		conditions = '[[page::' .. self.pagename .. ']] OR [[page::' .. self.pagename:gsub(' ', '_') .. ']]',
		limit = 5000,
	})

	local years = Set{}
	Array.forEach(queryData,
		---@param item broadcasters
		---@return number?
		function(item) years:add(tonumber(item.year_date)) end
	)

	return YearsActive.displayYears(years:toArray())
end

---@return Html?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) then
		return MatchTicker.participant({player = self.pagename})
	end
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local args = self.args
	for _, faction in pairs(self:readFactions(args.faction)) do
		table.insert(categories, Faction.toName(faction) .. ' Players')
	end

	return categories
end

---@param args table
---@return string
function CustomPlayer:nameDisplay(args)
	local factions = self:readFactions(args.faction)

	local factionIcons = table.concat(Array.map(factions, function(faction)
		return Faction.Icon{faction = faction, size = 'large'}
	end))

	local name = args.id or self.pagename

	return factionIcons .. '&nbsp;' .. name
end

---@param factionInput string?
---@return string
function CustomPlayer:getFactionData(factionInput)
	local factions = self:readFactions(factionInput)

	return table.concat(Array.map(factions, function(faction)
		faction = Faction.toName(faction)
		return '[[:Category:' .. faction .. ' Players|' .. faction .. ']]'
	end) or {}, ',&nbsp;')
end

---@param input string?
---@return string[]
function CustomPlayer:readFactions(input)
	return Faction.readMultiFaction(input, {alias = false, sep = ','})
end

---@param lpdbData table<string, string|number|table|nil>
---@param args table
---@param personType string
---@return table<string, string|number|table|nil>
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	local extradata = lpdbData.extradata

	local factions = self:readFactions(args.faction)

	extradata.faction = factions[1]
	extradata.faction2 = factions[2]

	if Variables.varDefault('factioncount') then
		extradata.factionhistorical = true
	end

	return lpdbData
end

return CustomPlayer

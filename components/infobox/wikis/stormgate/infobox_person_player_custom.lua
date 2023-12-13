---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local YearsActive = require('Module:YearsActive')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})
local MatchTicker = Lua.import('Module:MatchTicker/Custom', {requireDevIfEnabled = true})
local Person = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local RACE_FIELD_AS_CATEGORY_LINK = true
local CURRENT_YEAR = tonumber(os.date('%Y'))

local ROLES = {
	analyst = {category = 'Analyst', variable = 'Analyst', personType = 'Talent'},
	observer = {category = 'Observer', variable = 'Observer', personType = 'Talent'},
	host = {category = 'Host', variable = 'Host', personType = 'Talent'},
	journalist = {category = 'Journalist', variable = 'Journalist', personType = 'Talent'},
	expert = {category = 'Expert', variable = 'Expert', personType = 'Talent'},
	caster = {category = 'Caster', variable = 'Caster', personType = 'Talent'},
	talent = {category = 'Talent', variable = 'Talent', personType = 'Talent'},
	streamer = {category = 'Streamer', variable = 'Streamer', personType = 'Talent'},
	interviewer = {category = 'Interviewer', variable = 'Interviewer', personType = 'Talent'},
	photographer = {category = 'Photographer', variable = 'Photographer', personType = 'Talent'},
	organizer = {category = 'Organizer', variable = 'Organizer', personType = 'Staff'},
	coach = {category = 'Coache', variable = 'Coach', personType = 'Staff'},
	admin = {category = 'Admin', variable = 'Admin', personType = 'Staff'},
	manager = {category = 'Manager', variable = 'Manager', personType = 'Staff'},
	producer = {category = 'Producer', variable = 'Producer', personType = 'Staff'},
	player = {category = 'Player', variable = 'Player', personType = 'Player'},
}

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomPlayer = Class.new(Person)

local CustomInjector = Class.new(Injector)

local _player

---@param frame Frame
---@return string
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	_player = player

	player.args.history = TeamHistoryAuto.results{
		player = player.pagename,
		addlpdbdata = Namespace.isMain(),
	}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = _player.args
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {_player:getRaceData(args.race or 'unknown', RACE_FIELD_AS_CATEGORY_LINK)}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		local achievements = Achievements.player{
			noTemplate = true,
			onlyForFirstPrizePoolOfPage = true,
			player = _player.pagename,
			onlySolo = true,
		}
		if not achievements then return {} end

		return {
			Title{name = 'Achievements'},
			Center{content = {achievements}},
		}
	elseif id == 'history' and string.match(args.retired or '', '%d%d%d%d') then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end

	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Approx. Winnings ' .. CURRENT_YEAR,
			content = {_player.earningsPerYear[CURRENT_YEAR]}
		},
		Cell{
			name = Abbreviation.make('Years Active', 'Years active as a player'),
			content = {YearsActive.display({player = _player.pagename})
		}
		},
		Cell{
			name = Abbreviation.make('Years Active (caster)', 'Years active as a caster'),
			content = {_player:_getActiveCasterYears()}
		},
	}
end

---@return string|nil
function CustomPlayer:_getActiveCasterYears()
	if Namespace.isMain() then
		local queryData = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			query = 'year::date',
			conditions = '[[page::' .. self.pagename .. ']] OR [[page::' .. self.pagename:gsub(' ', '_') .. ']]',
			limit = 5000,
		})

		local years = Array.map(queryData, function(item) return tonumber(item.year_date) end)

		return Table.isNotEmpty(years) and YearsActive.displayYears(years) or nil
	end
end

---@return WidgetInjector
function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

---@return Html?
function CustomPlayer:createBottomContent()
	if Namespace.isMain() then
		return MatchTicker.participant({player = self.pagename})
	end
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local args = self.args
	for _, faction in pairs(self:readFactions(args.race)) do
		table.insert(categories, Faction.toName(faction) .. ' Players')
	end

	return categories
end

---@param args table
---@return string
function CustomPlayer:nameDisplay(args)
	local factions = self:readFactions(args.race)

	local raceIcons = table.concat(Array.map(factions, function(faction)
		return Faction.Icon{faction = faction, size = 'large'}
	end))

	local name = args.id or self.pagename

	return raceIcons .. '&nbsp;' .. name
end

---@param race string?
---@param asCategory boolean?
---@return string
function CustomPlayer:getRaceData(race, asCategory)
	local factions = self:readFactions(race)

	return table.concat(Array.map(factions, function(faction)
		faction = Faction.toName(faction)
		if asCategory then
			return '[[:Category:' .. faction .. ' Players|' .. faction .. ']]'
		end
		return '[[' .. faction .. ']]'
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
	local extradata = lpdbData.extradata or {}

	local factions = self:readFactions(args.race)

	extradata.faction = factions[1]
	extradata.faction2 = factions[2]
	extradata.role = CustomPlayer:_getRoleData(args.role).variable
	extradata.role2 = args.role2 and CustomPlayer:_getRoleData(args.role2).variable or nil

	if Variables.varDefault('factioncount') then
		extradata.factionhistorical = true
	end

	lpdbData.extradata = extradata

	return lpdbData
end

---@param args table
---@return string?
function CustomPlayer:getStatusToStore(args)
	if args.status then
		return mw.getContentLanguage():ucfirst(args.status)
	elseif args.death_date then
		return 'Deceased'
	elseif args.retired then
		return 'Retired'
	end
	return 'Active'
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = self:_getRoleData(args.role)
	return {store = roleData.personType, category = roleData.category}
end

---@param roleInput string?
---@return {category:string, variable: string, personType: string}
function CustomPlayer:_getRoleData(roleInput)
	return ROLES[roleInput] or ROLES.player
end

return CustomPlayer

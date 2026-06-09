---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local ActiveYears = Lua.import('Module:YearsActive')
local Class = Lua.import('Module:Class')
local Region = Lua.import('Module:Region')
local Math = Lua.import('Module:MathUtil')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local PlayerAchievements = Lua.import('Module:Infobox/Extension/Achievements')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = tonumber(os.date('%Y'))
local POWER_RANKINGS_DATA = Lua.import('Module:PowerRankings/Data', {loadData = true})

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param key string?
---@return string
local function normalizeKey(key)
	return string.lower((key or ''):gsub('[%s_]', ''))
end

---@param pageName string
---@param displayName string?
---@return integer? points
---@return integer? rank
local function fetchPowerRanking(pageName, displayName)
	local pageKey = normalizeKey(pageName)
	local nameKey = normalizeKey(displayName)
	local entry = Array.find(POWER_RANKINGS_DATA.players or {}, function(player)
		local entryKey = normalizeKey(player.link or player.name)
		return entryKey == pageKey or entryKey == nameKey
	end)

	return tonumber(entry.points), tonumber(entry.rank)
end

---@param frame Frame
---@return Widget
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.achievements = PlayerAchievements.player{}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local yearsActive = ActiveYears.display{player = caller.pagename}

		local currentYearEarnings = caller.earningsPerYear[CURRENT_YEAR]
		if currentYearEarnings then
			currentYearEarnings = Math.round(currentYearEarnings)
			currentYearEarnings = '$' .. mw.getContentLanguage():formatNum(currentYearEarnings)
		end

		local prPoints, prRank = fetchPowerRanking(caller.pagename, caller.name)

		return {
			Cell{name = 'Approx. Winnings ' .. CURRENT_YEAR, children = {currentYearEarnings}},
			Cell{name = 'Years active', children = {yearsActive}},
			Cell{
				name = Abbreviation.make{
					text = 'Epic Creator Code',
					title = 'Support-A-Creator Code used when purchasing Fortnite or Epic Games Store products',
				},
				children = {args.creatorcode}
			},
			Cell{
				name = '[[Fortnite Power Rankings|Fortnite PR]]',
				children = {prPoints and prRank and (prPoints .. ' (Rank #' .. prRank .. ')') or nil}
			},
		}
	elseif id == 'region' then return {}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.region = String.nilIfEmpty(Region.name({region = args.region, country = args.country}))

	return lpdbData
end

return CustomPlayer

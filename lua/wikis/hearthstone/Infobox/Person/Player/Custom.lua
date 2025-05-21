---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ActiveYears = require('Module:YearsActive')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local Region = require('Module:Region')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = tonumber(os.date('%Y'))

---@class HearthstoneInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = Role.run{role = player.args.role}
	player.role2 = Role.run{role = player.args.role2}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller

	if id == 'custom' then
		local yearsActive = ActiveYears.display{player = caller.pagename}

		local currentYearEarnings = caller.earningsPerYear[CURRENT_YEAR]
		if currentYearEarnings then
			currentYearEarnings = Math.round(currentYearEarnings)
			currentYearEarnings = '$' .. mw.getContentLanguage():formatNum(currentYearEarnings)
		end

		return {
			Cell{name = 'Approx. Winnings ' .. CURRENT_YEAR, content = {currentYearEarnings}},
			Cell{name = 'Years active', content = {yearsActive}},
		}
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {caller.role.display, caller.role2.display}}
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = (self.role or {}).variable
	lpdbData.extradata.role2 = (self.role2 or {}).variable

	lpdbData.region = String.nilIfEmpty(Region.name({region = args.region, country = args.country}))

	return lpdbData
end

return CustomPlayer

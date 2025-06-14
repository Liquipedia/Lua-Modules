---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ActiveYears = require('Module:YearsActive')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local PlayersSignatureLegends = require('Module:PlayersSignatureLegends')

local Player = Lua.import('Module:Infobox/Person')

local CURRENT_YEAR = tonumber(os.date('%Y'))

local Widgets = require('Module:Widget/All')
local Injector = Lua.import('Module:Widget/Injector')
local Cell = Widgets.Cell

---@class BrawlhallaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

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

		return {
			Cell{name = 'Approx. Winnings ' .. CURRENT_YEAR, content = {currentYearEarnings}},
			Cell{name = 'Years active', content = {yearsActive}},
			Cell{name = 'Main Legends', content = {PlayersSignatureLegends.get{player = caller.pagename}}},
		}
	elseif id == 'role' then return {}
	elseif id == 'history' and string.match(args.retired or '', '%d%d%d%d') then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

return CustomPlayer

---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class RematchInfoboxPlayer: Person
---@field basePageName string
local CustomPlayer = Class.new(Player)
---@class RematchInfoboxPlayerWidgetInjector: WidgetInjector
---@field caller RematchInfoboxPlayer
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

	if id == 'status' then
		local cells = {}
		if String.isNotEmpty(args.positions) then
			local positions = Array.parseCommaSeparatedString(args.positions, ',')
			local validPositions = Array.map(positions, String.nilIfEmpty)
			if #validPositions > 0 then
				local display = table.concat(Array.map(validPositions, function(pos)
					local capitalizedPos = String.upperCaseFirst(pos)
					return '[[:Category:' .. capitalizedPos .. 's|' .. capitalizedPos .. ']]'
				end), '<br>')
				local label = #validPositions > 1 and 'Positions' or 'Position'
				table.insert(cells, Cell{name = label, content = {display}})
			end
		end
		return cells
	end
	return widgets
end

---@param args table
---@param birthDisplay string
---@param personType string
---@param status PlayerStatus
---@return string[]
function CustomPlayer:getCategories(args, birthDisplay, personType, status)
	if not Namespace.isMain() then return {} end

	local categories = {}
	local roles = String.isNotEmpty(args.roles) and Array.parseCommaSeparatedString(args.roles, ',') or {}

	Array.forEach(roles, function(role)
		local roleCategory = role .. 's'
		table.insert(categories, roleCategory)
	end)

	Array.forEach(self:getLocations(), function(country)
		local demonym = Flags.getLocalisation(country)
		if demonym then
			Array.forEach(roles, function(role)
				local roleCategory = demonym .. ' ' .. role .. 's'
				table.insert(categories, roleCategory)
			end)
		end
	end)

	if String.isNotEmpty(args.positions) then
		local positions = Array.parseCommaSeparatedString(args.positions, ',')
		local validPositions = Array.filter(positions, function(pos)
			return String.isNotEmpty(pos)
		end)
		Array.forEach(validPositions, function(pos)
			local category = String.upperCaseFirst(pos) .. 's'
			table.insert(categories, category)
			Array.forEach(self:getLocations(), function(country)
				local demonym = Flags.getLocalisation(country)
				if demonym then
					table.insert(categories, demonym .. ' ' .. category)
				end
			end)
		end)
	end

	return categories
end

---@return string[]
function CustomPlayer:getLocations()
	return Array.map(self:getAllArgsForBase(self.args, 'country'), function(country)
		return Flags.CountryName{flag = country}
	end)
end

return CustomPlayer

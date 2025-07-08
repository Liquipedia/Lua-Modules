---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local function capitalize(str)
	if not str or str == '' then return str end
	return str:sub(1, 1):upper() .. str:sub(2):lower()
end

---@class CustomInfoboxPlayer: Person
---@field basePageName string
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))
	player.basePageName = mw.title.getCurrentTitle().baseText
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
			local positions = Array.map(
				String.split(args.positions, ','),
				function(pos) return String.trim(pos) end
			)
			local validPositions = Array.filter(positions, function(pos)
				return String.isNotEmpty(pos)
			end)
			if #validPositions > 0 then
				local display = table.concat(Array.map(validPositions, function(pos)
					local capitalizedPos = capitalize(pos)
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
	local roles = String.isNotEmpty(args.roles) and Array.map(
		String.split(args.roles, ','),
		function(role) return String.trim(role) end
	) or {}

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
		local positions = Array.map(
			String.split(args.positions, ','),
			function(pos) return String.trim(pos) end
		)
		local validPositions = Array.filter(positions, function(pos)
			return String.isNotEmpty(pos)
		end)
		Array.forEach(validPositions, function(pos)
			local category = capitalize(pos) .. 's'
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

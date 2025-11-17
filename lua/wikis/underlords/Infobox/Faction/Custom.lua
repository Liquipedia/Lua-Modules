---
-- @Liquipedia
-- page=Module:Infobox/Faction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local FactionInfobox = Lua.import('Module:Infobox/Faction')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class UnderlordsCustomFactionInfobox: FactionInfobox
---@field game string
local CustomFactionInfobox = Class.new(FactionInfobox)
---@class UnderlordsCustomFactionInfoboxInjector: WidgetInjector
---@field caller UnderlordsCustomFactionInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return string
function CustomFactionInfobox.run(frame)
	local infobox = CustomFactionInfobox(frame)

	infobox.args.informationType = 'Alliance'
	infobox:setWidgetInjector(CustomInjector(infobox))

	return infobox:createInfobox()
end

function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Rotation', children = {args.rotation}},
			Cell{name = 'Collision Size', children = {args.colsize}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomFactionInfobox:getWikiCategories(args)
	if args.removed then
		return {'Removed Content'}
	elseif args.unreleased then
		return {'Unreleased Alliances'}
	end
	return {'Alliances'}
end

---@param args table
---@return string?
function CustomFactionInfobox:nameDisplay(args)
	return args.alliancename or self.name
end

return CustomFactionInfobox

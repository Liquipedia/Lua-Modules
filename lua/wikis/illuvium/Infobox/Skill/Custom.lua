---
-- @Liquipedia
-- page=Module:Infobox/Skill/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Skill = Lua.import('Module:Infobox/Skill')

local Injector = Lua.import('Module:Widget/Injector')
local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class IlluviumSkillInfobox: SkillInfobox
local CustomSkill = Class.new(Skill)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomSkill.run(frame)
	local skill = CustomSkill(frame)

	skill:setWidgetInjector(CustomInjector(skill))

	return skill:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell({ name = 'Class', children = { args.class } }),
			Cell({ name = 'Type', children = { args.type } }),
			Cell({ name = 'Release Date', children = { args.releasedate } }),
			Cell({ name = 'Synergy Levels', children = { args.synergylevels } })
		)
	end

	return widgets
end

return CustomSkill

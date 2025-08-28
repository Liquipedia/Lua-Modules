---
-- @Liquipedia
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Injector = Lua.import('Module:Widget/Injector')
local Weapon = Lua.import('Module:Infobox/Weapon')

local Widgets = Lua.import('Module:Widget/All')
local Title = Widgets.Title
local Cell = Widgets.Cell

---@class IlluvItemInfobox: ItemInfobox
local CustomItem = Class.new(Weapon)
local CustomInjector = Class.new(Injector)

local CLASS_TYPE = {
    ['rogue'] = 'Rogue',
    ['fighter'] = 'Fighter',
    ['psion'] = 'Psion',
    ['empath'] = 'Empath',
    ['bulwark'] = 'Bulwark',
}

---@param frame Frame
---@return Html
function CustomItem.run(frame)
    local item = CustomItem(frame)
    item:setWidgetInjector(CustomInjector(item))

    return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
    local args = self.caller.args
    if id == 'weapon' then
        return {
            Title { children = 'Weapon Information' },
            Cell { name = 'Weapon type', children = { args.type } },
            Cell { name = 'Class', { CLASS_TYPE(args.class or ''):lower() } },
            Cell { name = 'Tier', children = { args.tier } }
        }
    elseif id == 'suit' then
        return {
            Title { children = 'Suit Information' },
            Cell { name = 'Name', children = { args.name } },
            Cell { name = 'Tier', children = { args.tier } },
            Cell { name = 'Description', children = { args.description } }
        }
    elseif id == 'augment' then
        return {
            Title { children = 'Augment Information' },
            Cell { name = 'Type', children = { args.type } },
            Cell { name = 'Trigger Type', children = { args.trigger_type } },
            Title { children = 'Mastery Point Costs' },
            Cell { name = 'Lesser', children = { args.lesser } },
            Cell { name = 'Greater', children = { args.greater } },
            Cell { name = 'Exalted', children = { args.exalted } }
        }
    end

    return widgets
end

return CustomItem

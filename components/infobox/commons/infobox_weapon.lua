-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local BasicInfobox = require('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Weapon = Class.new(BasicInfobox)

function Weapon.run(frame)
    local weapon = Weapon(frame)
    return weapon:createInfobox()
end

function Weapon:createInfobox()
    local infobox = self.infobox
    local args = self.args

    local widgets = {
        Header{
            name = self:nameDisplay(args),
            image = args.image,
            imageDefault = args.default,
            imageDark = args.imagedark or args.imagedarkmode,
            imageDefaultDark = args.defaultdark or args.defaultdarkmode,
        },
        Center{content = {args.caption}},
        Title{name = (args.informationType or 'Weapon') .. ' Information'},
        Customizable{
            id = 'class',
            children = {
                Cell{name = 'Class', content = {args.class}},
            }
        },
        Customizable{
            id = 'damage',
            children = {
                Cell{name = 'Base Damage', content = {args.damage}},
            }
        },
        Customizable{
            id = 'magazine',
            children = {
                Cell{name = 'Magazine Size', content = {args.magazine}},
            }
        },
        Customizable{
            id = 'ammo',
            children = {
                Cell{name = 'Ammo Capacity', content = {args.ammo}},
            }
        },
        Customizable{
            id = 'rof',
            children = {
                Cell{name = 'Rate of Fire', content = {args.rof}},
            }
        },
        Customizable{
            id = 'reload',
            children = {
                Cell{name = 'Reload Speed', content = {args.reload}},
            }
        },
        Customizable{
            id = 'mode',
            children = {
                Cell{name = 'Firing Mode', content = {args.mode}},
            }
        },
        Customizable{id = 'custom', children = {}},
        Center{content = {args.footnotes}},
    }

    infobox:categories('Weapons')
    infobox:categories(unpack(self:getWikiCategories(args)))

    local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
        self:setLpdbData(args)
    end

    return builtInfobox
end

function Weapon:getWikiCategories(args)
    return {}
end

function Weapon:nameDisplay(args)
    return args.name
end

function Weapon:setLpdbData(args)
end

return Weapon

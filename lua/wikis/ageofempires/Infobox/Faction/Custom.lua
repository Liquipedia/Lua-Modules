---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Faction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local FactionInfobox = Lua.import('Module:Infobox/Faction')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Icon = require('Module:Widget/Image/Icon/Image')

---@class CustomFactionInfobox: FactionInfobox
local CustomFactionInfobox = Class.new(FactionInfobox)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomFactionInfobox.run(frame)
	local infobox = CustomFactionInfobox(frame)

    infobox.args.informationType = 'Civilization'
    infobox.args.lpdbType = 'civ'

    infobox:setWidgetInjector(CustomInjector(infobox))

    return infobox:createInfobox()
end

function CustomInjector:parse(id, widgets)
    ---@type CustomFactionInfobox
	local caller = self.caller
	local args = caller.args

    if id == 'release' then
        return {
            args.introduced and Cell{
                name = 'First introduced',
                content = {
                    caller._makeIntroducedIcon(args.introduced),
                    Page.makeInternalLink(args.introduced)
                }
            } or nil
        }
    elseif id == 'custom' then
        Array.extendWith(widgets,
            Cell{
                name = Page.makeInternalLink('Architectural Style', 'Architectures (building styles)'),
                content = {args.architecture}
            },
            Cell{name = 'Continent', content = {args.continent}},
            --TODO: Game?
            Cell{
                name = Page.makeInternalLink('Ingame classification', 'Civilizations classification'),
                content = Array.map(
                    caller:getAllArgsForBase(args, 'type'),
                    function (t)
                        return t .. ' civilization'
                    end
                )
            },
            Cell{
                name = 'Unique buildings',
                content = Array.map(
                    caller:getAllArgsForBase(args, 'building'),
                    Page.makeInternalLink
                )
            },
            Cell{
                name = 'Unique units',
                content = Array.map(
                    caller:getAllArgsForBase(args, 'unit'),
                    Page.makeInternalLink
                )
            },
            args.tech1 and Cell{
                name = 'Unique technologies',
                content = {
                    caller._makeAgeIcon('Castle'),
                    Page.makeInternalLink(args.tech1),
                    caller._makeAgeIcon('Imperial'),
                    Page.makeInternalLink(args.tech2),
                }
            }
        )
    end

    return widgets
end

---@param introduced string?
---@return Widget
function CustomFactionInfobox._makeIntroducedIcon(introduced)
    return Icon{
        image = 'Aoe2 ' .. introduced .. 'Icon.png',
        size = '18px',
        link = introduced
    }
end

---@param age string?
---@return Widget
function CustomFactionInfobox._makeAgeIcon(age)
    return Icon{
        image = age .. ' Age AoE2 logo.png',
        size = '18px',
        link = age .. ' Age'
    }
end

return CustomFactionInfobox

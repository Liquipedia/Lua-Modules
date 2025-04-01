local Lua = require('Module:Lua')
local WidgetFactory = Lua.import('Module:Widget/Factory')
local ____exports = {}
local ____Image = Lua.import("Module:Image")
local Image = ____Image.default
function ____exports.default(____bindingPattern0)
    local text
    text = ____bindingPattern0.text
    return WidgetFactory.createElement(
        "div",
        {className = "show-when-logged-in navigation-not-searchable ambox-wrapper ambox\n\t\t\t\twiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"},
        WidgetFactory.createElement(
            "table",
            nil,
            WidgetFactory.createElement(
                "tr",
                nil,
                WidgetFactory.createElement(
                    "td",
                    {className = "ambox-image"},
                    WidgetFactory.createElement(Image, {src = "Emblem-important.svg", alt = "Important", width = "40"})
                ),
                WidgetFactory.createElement("td", {className = "ambox-text"}, text)
            )
        )
    )
end
return ____exports

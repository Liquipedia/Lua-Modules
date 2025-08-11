---
-- @Liquipedia
-- page=Module:Widget/Infobox/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Accommodation = Lua.import('Module:Widget/Infobox/Accommodation')
Widgets.Breakdown = Lua.import('Module:Widget/Infobox/Breakdown')
Widgets.Cell = Lua.import('Module:Widget/Infobox/Cell')
Widgets.Center = Lua.import('Module:Widget/Infobox/Center')
Widgets.Chronology = Lua.import('Module:Widget/Infobox/ChronologyContainer')
Widgets.Header = Lua.import('Module:Widget/Infobox/Header')
Widgets.Highlights = Lua.import('Module:Widget/Infobox/Highlights')
Widgets.Links = Lua.import('Module:Widget/Infobox/Links')
Widgets.Location = Lua.import('Module:Widget/Infobox/Location')
Widgets.Organizers = Lua.import('Module:Widget/Infobox/Organizers')
Widgets.Table = Lua.import('Module:Widget/Infobox/Table')
Widgets.Title = Lua.import('Module:Widget/Infobox/Title')
Widgets.Venue = Lua.import('Module:Widget/Infobox/Venue')

return Widgets

---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

Widgets.Cell = require('Module:Infobox/Widget/Cell')
Widgets.Header = require('Module:Infobox/Widget/Header')
Widgets.Center = require('Module:Infobox/Widget/Center')
Widgets.Title = require('Module:Infobox/Widget/Title')
Widgets.Customizable = require('Module:Infobox/Widget/Customizable')
Widgets.Links = require('Module:Infobox/Widget/Links')
Widgets.Chronology = require('Module:Infobox/Widget/Chronology')
Widgets.Builder = require('Module:Infobox/Widget/Builder')
Widgets.Breakdown = require('Module:Infobox/Widget/Breakdown')
Widgets.Error = require('Module:Infobox/Widget/Error')

return Widgets

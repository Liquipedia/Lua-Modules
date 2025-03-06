---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/ThisDay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ThisDayWidgets = {}

ThisDayWidgets.Title = Lua.import('Module:Widget/MainPage/ThisDay/Title')
ThisDayWidgets.Content = Lua.import('Module:Widget/MainPage/ThisDay/Content')

return ThisDayWidgets

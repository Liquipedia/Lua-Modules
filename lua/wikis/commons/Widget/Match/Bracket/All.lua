---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Lua = require('Module:Lua')

Widgets.Score = Lua.import('Module:Widget/Match/Bracket/Score')
Widgets.ScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer/Custom')

return Widgets

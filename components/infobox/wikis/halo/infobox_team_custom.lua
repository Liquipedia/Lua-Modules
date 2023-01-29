---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local String = require('Module:String')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)
	return team:createInfobox()
end

return CustomTeam

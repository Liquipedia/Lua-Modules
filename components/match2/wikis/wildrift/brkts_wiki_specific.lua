---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true}))

WikiSpecific.defaultIcon = 'Wild_Rift_Teamcard.png'

return WikiSpecific

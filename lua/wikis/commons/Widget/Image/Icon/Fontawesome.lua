---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/Fontawesome
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Icon = Lua.import('Module:Icon')
local Component = Lua.import('Module:Widget/Component')

return Component.component(Icon.makeIcon)

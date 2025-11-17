---
-- @Liquipedia
-- page=Module:Infobox/Effect/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Effect = Lua.import('Module:Infobox/Effect')

---@class CustomEffectInfobox: EffectInfobox
local CustomEffect = Class.new(Effect)

---@param frame Frame
---@return Html
function CustomEffect.run(frame)
	return CustomEffect(frame):createInfobox()
end

return CustomEffect

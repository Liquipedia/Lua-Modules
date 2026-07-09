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
---@operator call(Frame): CustomEffectInfobox
local CustomEffect = Class.new(Effect)

---@param frame Frame
---@return VNode
function CustomEffect.run(frame)
	return CustomEffect(frame):createInfobox()
end

return CustomEffect

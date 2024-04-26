---
-- @Liquipedia
-- wiki=commons
-- page=Module:TransferRow/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[old one:
https://liquipedia.net/commons/index.php?title=Module:Transfer/dev&action=edit
]]

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})

local TransferRowDisplay = {}

---@param transfers transfer[]
---@return Html?
function TransferRowDisplay.run(transfers)
	--todo
end

return TransferRowDisplay

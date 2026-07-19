---
-- @Liquipedia
-- page=Module:TransferRow/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')

local TransferRow = Lua.import('Module:TransferRow')

---@class CustomTransferRow: TransferRow
---@operator call(table): CustomTransferRow
local CustomTransferRow = Class.new(TransferRow)

---@param frame Frame
---@return VNode
function CustomTransferRow.transfer(frame)
	return CustomTransferRow(Arguments.getArgs(frame)):read():store():build()
end

---@param frame Frame
---@return VNode
function CustomTransferRow.rumour(frame)
	frame.args.isRumour = true
	return CustomTransferRow.transfer(frame)
end

return CustomTransferRow

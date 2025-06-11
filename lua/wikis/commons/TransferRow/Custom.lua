---
-- @Liquipedia
-- page=Module:TransferRow/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TransferRow = Lua.import('Module:TransferRow')

---@class CustomTransferRow: TransferRow
local CustomTransferRow = Class.new(TransferRow)

---@param frame Frame
---@return Html?
function CustomTransferRow.transfer(frame)
	return CustomTransferRow(Arguments.getArgs(frame)):read():store():build()
end

---@param frame Frame
---@return Html?
function CustomTransferRow.rumour(frame)
	frame.args.isRumour = true
	return CustomTransferRow.transfer(frame)
end

return CustomTransferRow

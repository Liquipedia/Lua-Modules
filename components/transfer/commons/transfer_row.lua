---
-- @Liquipedia
-- wiki=commons
-- page=Module:TransferRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[old one:
https://liquipedia.net/commons/index.php?title=Module:Transfer/dev&action=edit
]]

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local TransferRowDisplay = Lua.import('Module:TransferRow/Display', {requireDevIfEnabled = true})

---@class TransferRowConfig
---@field storage boolean?
---todo: add needed fields of the class

---@class TransferRow: BaseClass
---@field config TransferRowConfig
---@field transfers transfer[]
---@field references string[]
---@field args table
local TransferRow = Class.new(
	---@param args table
	---@return self
	function(self, args)
		self.args = args

		return self
	end
)

---@return self
function TransferRow:read()
	self.config = self:readConfig()
	self.transfers = self:readInput()
	self.references = self:readReferences()

	return self
end

---@return TransferRowConfig
function TransferRow:readConfig()
	--todo
end

---@return transfer[]
function TransferRow:readInput()
	--todo
end

---@return string[]
function TransferRow:readReferences()
	--todo
end

---@return self
function TransferRow:store()
	if not self.config.storage then	return self end

	Array.forEach(self.transfers, function(transfer, transferIndex)
		mw.ext.LiquipediaDB.lpdb_transfer(TransferRow._objectName(transfer), Json.stringifySubTables(transfer))
	end)

	return self
end

---@param transfer transfer
---@return string
function TransferRow._objectName(transfer)
	return 'transfer_' .. transfer.date .. '_' .. string.format('%06d', transfer.extradata.transferSortIndex)
end

---@return Html?
function TransferRow:build()
	return TransferRowDisplay.run(self.transfers, self.config)
end

return TransferRow
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

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})

---@class TransferRowDisplayConfig
---@field displayTeamName boolean
---@field iconFunction string?
---@field iconModule string?
---@field iconParam string?
---@field iconTransfers boolean
---@field platformIcons boolean
---@field positionConvert string?
---@field referencesAsTable boolean
---@field syncPlayers boolean

---@class TransferRowDisplay: BaseClass
---@field transfers transfer[]
---@field config TransferRowDisplayConfig
local TransferRowDisplay = Class.new(
	---@param transfers transfer[]
	---@return self
	function(self, transfers)
		self.config = Info.config.squads
		self.transfers = self:_enrichTransfers(transfers)

		return self
	end
)

---@param transfers transfer[]
---@return transfer[]
function TransferRowDisplay:_enrichTransfers(transfers)
	if Logic.isEmpty(transfers) then return {} end

	--todo
end

---@return Html?
function TransferRowDisplay:display()
	if Logic.isEmpty(self.transfers) then return end

	--todo
end

return TransferRowDisplay

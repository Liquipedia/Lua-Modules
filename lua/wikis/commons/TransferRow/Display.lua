---
-- @Liquipedia
-- page=Module:TransferRow/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local Info = Lua.import('Module:Info', {loadData = true})
local Platform = Lua.import('Module:Platform')
local TransferRef = Lua.import('Module:Transfer/References')

local TransferRowWidget = Lua.import('Module:Widget/Transfer/Row')

local HAS_PLATFORM_ICONS = Lua.moduleExists('Module:Platform/data')

---@class enrichedTransfer
---@field from {teams: string[], roles: string[]}
---@field to {teams: string[], roles: string[]}
---@field platform string?
---@field displayDate string
---@field date string
---@field wholeteam boolean
---@field players transferPlayer[]
---@field references string[]
---@field confirmed boolean?
---@field confidence string?
---@field isRumour boolean?

---@class transferPlayer: standardPlayer
---@field icons string[]
---@field faction string?
---@field chars string[]

---@class TransferRowDisplay: BaseClass
---@field transfer enrichedTransfer
---@field config {showTeamName: boolean?}
local TransferRowDisplay = Class.new(
	---@param transfers transfer[]
	---@return self
	function(self, transfers)
		self.config = {
			showTeamName = (Info.config.transfers or {}).showTeamName,
		}
		self.transfer = self:_enrichTransfers(transfers)

		return self
	end
)

---@param transfers transfer[]
---@return enrichedTransfer
function TransferRowDisplay:_enrichTransfers(transfers)
	if Logic.isEmpty(transfers) then return {} end

	local transfer = transfers[1]

	local date = DateExt.toYmdInUtc(transfer.date)

	return {
		from = {
			teams = {
				String.nilIfEmpty(transfer.fromteamtemplate),
				String.nilIfEmpty(transfer.extradata.fromteamsectemplate),
			},
			roles = {
				String.nilIfEmpty(transfer.role1),
				String.nilIfEmpty(transfer.extradata.role1sec),
			},
		},
		to = {
			teams = {
				String.nilIfEmpty(transfer.toteamtemplate),
				String.nilIfEmpty(transfer.extradata.toteamsectemplate),
			},
			roles = {
				String.nilIfEmpty(transfer.role2),
				String.nilIfEmpty(transfer.extradata.role2sec),
			},
		},
		platform = HAS_PLATFORM_ICONS and self:_displayPlatform(transfer.extradata.platform) or nil,
		displayDate = String.nilIfEmpty(transfer.extradata.displaydate) or date,
		date = date,
		wholeteam = Logic.readBool(transfer.wholeteam),
		players = self:_readPlayers(transfers),
		references = self:_getReferences(transfers),
		confirmed = transfer.extradata.confirmed,
		confidence = transfer.extradata.confidence,
		isRumour = transfer.extradata.isRumour,
	}
end

---@param platform string
---@return string?
function TransferRowDisplay:_displayPlatform(platform)
	if not HAS_PLATFORM_ICONS then return end
	if Logic.isEmpty(platform) then return '' end
	return Platform._getIcon(platform) or ''
end

---@param transfers transfer[]
---@return transferPlayer[]
function TransferRowDisplay:_readPlayers(transfers)
	return Array.map(transfers, function(transfer)
		local extradata = transfer.extradata
		return {
			pageName = transfer.player,
			displayName = String.nilIfEmpty(extradata.displayname) or transfer.player,
			flag = transfer.nationality,
			icons = {String.nilIfEmpty(extradata.icon), String.nilIfEmpty(extradata.icon2)},
			faction = extradata.faction,
			chars = extradata.chars,
		}
	end)
end

---@param transfers transfer[]
---@return string[]
function TransferRowDisplay:_getReferences(transfers)
	local references = {}
	Array.forEach(transfers, function(transfer)
		Array.extendWith(references, TransferRef.fromStorageData(transfer.reference))
	end)
	references = TransferRef.makeUnique(references)

	return Array.map(references, TransferRef.createReferenceIconDisplay)
end

---@return Widget?
function TransferRowDisplay:build()
	local transfer = self.transfer
	if Logic.isEmpty(transfer) then return end

	return TransferRowWidget{
		transfer = self.transfer,
		showTeamName = self.config.showTeamName
	}
end

return TransferRowDisplay

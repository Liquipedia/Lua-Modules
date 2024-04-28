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

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Info = Lua.import('Module:Info', {loadData = true})
local Platform = Lua.requireIfExists('Module:Platform')

local SPECIAL_ROLES = {'retired', 'retirement', 'inactive', 'military', 'passed away'}

---@class TransferRowDisplayConfig
---@field showTeamName boolean
---@field iconModule string?
---@field iconParam string?
---@field iconTransfers boolean
---@field platformIcons boolean
---@field positionConvert string?
---@field referencesAsTable boolean
---@field syncPlayers boolean

---@class enrichedTransfer
---@field from {teams: string[], roles: string[]}
---@field to {teams: string[], roles: string[]}
---@field platform string?
---@field displayDate string
---@field date string
---@field wholeteam boolean
---@field players transferPlayer[]
---@field references b[]

---@class transferPlayer: standardPlayer
---@field isSubstitute boolean
---@field position string?
---@field icons string[]
---@field faction string?
---@field race string?
---@field chars string[]

---@class TransferRowDisplay: BaseClass
---@field transfer enrichedTransfer
---@field config TransferRowDisplayConfig
---@field display Html
local TransferRowDisplay = Class.new(
	---@param transfers transfer[]
	---@return self
	function(self, transfers)
		self.config = Info.config.squads
		self.transfer = self:_enrichTransfers(transfers)
		self.display = mw.html.create('div')

		return self
	end
)

---@param transfers transfer[]
---@return enrichedTransfer
function TransferRowDisplay:_enrichTransfers(transfers)
	if Logic.isEmpty(transfers) then return {} end

	local config = self.config

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
		platform = config.platformIcons and self:_displayPlatform(transfer.extradata.platform) or nil,
		displayDate = String.nilIfEmpty(transfer.extradata.displaydate) or date,
		date = date,
		wholeteam = Logic.readBool(transfer.wholeteam),
		players = self:_readPlayers(transfers),
		references = self:_getReferences(transfers),
	}
end

---@param platform string
---@return string?
function TransferRowDisplay:_displayPlatform(platform)
	if not self.config.platformIcons then return end
	if Logic.isEmpty(platform) then return '' end
	return Platform._getIcon(platform) or ''
end

---@param transfers transfer[]
---@return transferPlayer[]
function TransferRowDisplay:_readPlayers(transfers)

end

---@return Html?
function TransferRowDisplay:build()
	local transfer = self.transfer
	if Logic.isEmpty(transfer) then return end

	return self
		:cssClass()
		:date()
		:platform()
		:players()
		:from()
		:icon()
		:to()
		:references()
		:create()
end

---@return self
function TransferRowDisplay:cssClass()
	self.display:addClass('divRow mainpage-transfer-' .. self:_getStatus())
	return self
end

---@return string
function TransferRowDisplay:_getStatus()
	local transfer = self.transfer
	if transfer.from.teams[1] and transfer.to.teams[1] then
		return 'neutral'
	elseif transfer.from.teams[1] then
		return 'from-team'
	elseif transfer.to.teams[1] then
		return 'to-team'
	elseif self:_isSpecialRole(transfer.from.roles[1]) then
		return 'to-team'
	elseif self:_isSpecialRole(transfer.to.roles[1]) then
		return 'from-team'
	end

	return 'neutral'
end

---@param role string?
---@return boolean
function TransferRowDisplay:_isSpecialRole(role)
	if not role then return false end
	role = role:lower()
	return Table.includes(SPECIAL_ROLES, role)
end

---@return self
function TransferRowDisplay:date()
	self.display:tag('div')
		:addClass('divCell Date')
		:wikitext(self.transfer.date)
	return self
end

---@return self
function TransferRowDisplay:platform()
	if not self.transfer.platform then return self end

	self.display:tag('div')
		:addClass('divCell GameIcon')
		:wikitext(self.transfer.platform)

	return self
end

---@return self
function TransferRowDisplay:players()

end

---@return self
function TransferRowDisplay:from()
	self.display:node(self:_displayTeam{
		data = self.transfer.from,
		date = self.transfer.date,
		isOldTeam = true,
	})
	return self
end

---@param args {isOldTeam: boolean, date: string, data: {teams: string[], roles: string[]}}
---@return Html
function TransferRowDisplay:_displayTeam(args)
	local showTeamName = self.config.showTeamName
	local isOldTeam = args.isOldTeam
	local data = args.data
	local align = isOldTeam and 'right' or 'left'
	local teamCell = mw.html.create('div')
		:addClass('divCell Team' .. (args.isOldTeam and 'OldTeam' or 'NewTeam'))

	if showTeamName then
		teamCell:css('text-align', align)
	end

	if not data.teams[1] and not data.roles[1] then
		return teamCell:node(self:_createRole{'&nbsp;None&nbsp;'}:css('margin-' .. align, showTeamName and '60px' or nil))
	end

	local displayTeam = showTeamName and
		(isOldTeam and mw.ext.TeamTemplate.team2short or mw.ext.TeamTemplate.teamshort) or
		mw.ext.TeamTemplate.teamicon

	teamCell:node(table.concat(Array.map(data.teams, function(team)
		return displayTeam(team, args.date)
	end), '/'))

	local roleCell = self:_createRole(data.roles, data.teams[1])

	if roleCell and showTeamName and not data.teams[1] then
		roleCell:css('margin-' .. align, '60px')
	end

	if data.teams[1] then
		teamCell:newline()
	end

	return teamCell:node(roleCell)
end

---@param roles string[]
---@param team string?
---@return Html?
function TransferRowDisplay:_createRole(roles, team)
	if Logic.isEmpty(roles) then return end

	local roleCell = mw.html.create('span')
		:css('font-style', 'italic')
		:wikitext('(' .. table.concat(roles, '/') .. ')')

	if Logic.isEmpty(team) then
		return roleCell
	end

	return roleCell:css('font-size', '85%')
end

---@return self
function TransferRowDisplay:icon()
	local iconCell = self.display:tag('div')
		:addClass('divCell Icon')
		:css('width', '70px')

	local config = self.config
	if not config.iconModule or not config.iconTransfers then
		iconCell:css('font-size','larger'):wikitext('&#x21d2;')
		return self
	end

	local iconModule = Lua.import(config.iconModule, {loadData = true})
	local getIcon = function(icon) return iconModule[string.lower(icon)] end

	local iconRows = Array.map(self.transfer.players, function(player)
		return self:_createPosRow(player.icons, getIcon)
	end)


end
function p._createPosRow(frame, iconLeft, iconRight, iconModule)
	local function createIcon(iconInput)
		if iconInput then
			local iconTemp = iconModule{iconInput, faction = iconInput}
			if not iconTemp then
				mw.log( 'No entry found in Module:PositionIcon/data: ' .. iconInput)
				return '[[File:Logo filler event.png|16px|link=]][[Category:Pages with transfer errors]] '
			end
			return iconTemp
		end
	end

	return (createIcon(iconLeft) or '')  .. '&nbsp;&#x21d2;&nbsp;' .. (createIcon(iconRight) or '')
end
function p._createIcon(frame, args)
	local div = mw.html.create('div'):attr('class', 'divCell Icon'):css('width', '70px')

	if args.iconModule and not args.iconPlayer then
		if args.iconFunction then
			getIcon = require(args.iconModule)[args.iconFunction]
		else
			getIcon = function(iconData) return mw.loadData(args.iconModule)[string.lower(iconData[1])] end
		end

		div:wikitext(p._createPosRow(frame, args.posIcon, args.posIcon_2, getIcon))
		local nameIndex = 2
		while (args['name' .. nameIndex] ~= nil) do
			div:wikitext('<br/>')
			div:wikitext(p._createPosRow(
				frame,
				args['posIcon' .. nameIndex],
				args['posIcon' .. nameIndex .. '_2'],
				getIcon
			))
			nameIndex = nameIndex + 1
		end
	else
		-- The Arrow
		div:css('font-size','larger'):wikitext('&#x21d2;')
	end

	return div
end

---@return self
function TransferRowDisplay:to()
	self.display:node(self:_displayTeam{
		data = self.transfer.to,
		date = self.transfer.date,
		isOldTeam = false,
	})
	return self
end

---@return self
function TransferRowDisplay:references()

end

---@return Html
function TransferRowDisplay:create()
	return self.display
end

return TransferRowDisplay

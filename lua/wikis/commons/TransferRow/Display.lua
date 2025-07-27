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
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local IconModule = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})
local Info = Lua.import('Module:Info', {loadData = true})
local Platform = Lua.import('Module:Platform')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local TransferRef = Lua.import('Module:Transfer/References')

local HAS_PLATFORM_ICONS = Lua.moduleExists('Module:Platform/data')
local EMPTY_POSITION_ICON = '[[File:Logo filler event.png|16px|link=]]'
local SPECIAL_ROLES = {'retired', 'inactive', 'military', 'passed away'}
local TRANSFER_ARROW = '&#x21d2;'
local RUMOUR_STATUS_TO_ICON_ARGS = {
	correct = {iconName = 'correct', color = 'forest-green-text'},
	wrong = {iconName = 'wrong', color = 'cinnabar-text'},
	uncertain = {iconName = 'uncertain', color = 'bright-sun-text'},
}
local CONFIDENCE_TO_COLOR = {
	certain = 'forest-theme-dark-text',
	likely = 'bright-sun-non-text',
	possible = 'california-non-text',
	unlikely = 'cinnabar-theme-dark-text',
	unknown = 'gigas-theme-light-alt-text',
}

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
---@field display Html
local TransferRowDisplay = Class.new(
	---@param transfers transfer[]
	---@return self
	function(self, transfers)
		self.config = {
			showTeamName = (Info.config.transfers or {}).showTeamName,
		}
		self.transfer = self:_enrichTransfers(transfers)
		self.display = mw.html.create('div')

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

---@return Html?
function TransferRowDisplay:build()
	local transfer = self.transfer
	if Logic.isEmpty(transfer) then return end

	return self
		:cssClass()
		:status()
		:confidence()
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
	if self.transfer.isRumour then
		self.display:addClass('RumourRow')
		return self
	end
	self.display:addClass('divRow mainpage-transfer-' .. self:_getStatus())
	return self
end

---@return self
function TransferRowDisplay:status()
	if not self.transfer.isRumour then return self end

	self.display:tag('div')
		:addClass('divCell Status')
		:node(Icon.makeIcon(RUMOUR_STATUS_TO_ICON_ARGS[self.transfer.confirmed]))

	return self
end

---@return self
function TransferRowDisplay:confidence()
	if not self.transfer.isRumour then return self end

	local confidence = self.transfer.confidence

	self.display:tag('div')
		:addClass('divCell Confidence')
		:addClass(CONFIDENCE_TO_COLOR[confidence])
		:css('font-weight', 'bold')
		:wikitext(confidence and mw.getContentLanguage():ucfirst(confidence) or nil)

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
		:wikitext(self.transfer.displayDate)
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
	local playersCell = self.display:tag('div')
		:addClass('divCell Name')

	Array.forEach(self.transfer.players, function(player, playerIndex)
		playersCell:node(PlayerDisplay.BlockPlayer{player = player})
	end)

	return self
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
		:addClass('divCell Team ' .. (isOldTeam and 'OldTeam' or 'NewTeam'))

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
	end), ' / '))

	local roleCell = self:_createRole(data.roles, data.teams[1])

	if roleCell and showTeamName and not data.teams[1] then
		roleCell:css('margin-' .. align, '60px')
	end

	if data.teams[1] then
		---`teamCell:newline()` does not work here ...
		teamCell:wikitext('<br>')
	end

	return teamCell:node(roleCell)
end

---@param roles string[]
---@param team string?
---@return Html?
function TransferRowDisplay:_createRole(roles, team)
	if Logic.isEmpty(roles) then return end

	local rolesText = table.concat(Array.filter(roles, Logic.isNotEmpty), '/')

	local roleCell = mw.html.create('span')
		:css('font-style', 'italic')

	if Logic.isEmpty(team) then
		return roleCell:wikitext(rolesText)
	end

	return roleCell
		:css('font-size', '85%')
		:wikitext('(' .. rolesText .. ')')
end

---@return self
function TransferRowDisplay:icon()
	local iconCell = self.display:tag('div')
		:addClass('divCell Icon')
		:css('width', '70px')

	if not IconModule then
		iconCell:css('font-size','larger'):wikitext(TRANSFER_ARROW)
		return self
	end

	---@param iconInput string?
	---@return string
	local getIcon = function(iconInput)
		if Logic.isEmpty(iconInput) then
			return EMPTY_POSITION_ICON
		end
		---@cast iconInput -nil
		local icon = IconModule[iconInput:lower()]
		if not icon then
			mw.log( 'No entry found in Module:PositionIcon/data: ' .. iconInput)
			mw.ext.TeamLiquidIntegration.add_category('Pages with transfer errors')
			return EMPTY_POSITION_ICON
		end

		return icon
	end

	local targetRoleIsSpecialRole = TransferRowDisplay:_isSpecialRole(self.transfer.to.roles[1])

	local iconRows = Array.map(self.transfer.players, function(player)
		return getIcon(player.icons[1]) .. '&nbsp;' .. TRANSFER_ARROW ..
			'&nbsp;' .. getIcon(player.icons[2] or targetRoleIsSpecialRole and player.icons[1] or nil)
	end)
	iconCell:wikitext(table.concat(iconRows, '<br>'))

	return self
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
	self.display:tag('div')
		:addClass('divCell Ref')
		:wikitext(table.concat(self.transfer.references, '<br>'))
	return self
end

---@return Html
function TransferRowDisplay:create()
	return self.display
end

return TransferRowDisplay

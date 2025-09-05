---
-- @Liquipedia
-- page=Module:Widget/Transfer/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local IconModule = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Platform = Lua.import('Module:Platform')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local References = Lua.import('Module:Transfer/References')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local EMPTY_POSITION_ICON = IconImage{imageLight = 'Logo filler event.png', size = '16px'}
local HAS_PLATFORM_ICONS = Lua.moduleExists('Module:Platform/data')
local SPECIAL_ROLES = {'retired', 'inactive', 'military', 'passed away'}
local TRANSFER_STATUS_TO_ICON_NAME = {
	neutral = 'transferbetween',
	['from-team'] = 'transfertofreeagent',
	['to-team'] = 'transferfromfreeagent',
}
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

local function createDivCell(props)
	return HtmlWidgets.Div{
		classes = Array.extend('divCell', props.classes),
		css = props.css,
		children = props.children
	}
end

---@class TransferRowWidget: Widget
---@operator call({transfers: transfer[], showTeamName: boolean?}): TransferRowWidget
---@field props {transfers: transfer[], showTeamName: boolean?}
---@field transfer enrichedTransfer
local TransferRowWidget = Class.new(Widget,
	---@param self self
	---@param input {transfers: transfer[], showTeamName: boolean?}
	function (self, input)
		self.transfer = self:_enrichTransfers(input.transfers)
	end
)

---@return Widget?
function TransferRowWidget:render()
	local transfer = self.transfer
	if Logic.isEmpty(transfer) then return end

	return HtmlWidgets.Div{
		classes = self:_getClasses(),
		children = WidgetUtil.collect(
			self:status(),
			self:confidence(),
			self:date(),
			self:platform(),
			self:players(),
			self:from(),
			self:icon(),
			self:to(),
			self:references()
		)
	}
end

---@private
---@param transfers transfer[]
---@return enrichedTransfer
function TransferRowWidget:_enrichTransfers(transfers)
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

---@private
---@param platform string
---@return string?
function TransferRowWidget:_displayPlatform(platform)
	if not HAS_PLATFORM_ICONS then return end
	if Logic.isEmpty(platform) then return '' end
	return Platform._getIcon(platform) or ''
end

---@private
---@param transfers transfer[]
---@return transferPlayer[]
function TransferRowWidget:_readPlayers(transfers)
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

---@private
---@param transfers transfer[]
---@return string[]
function TransferRowWidget:_getReferences(transfers)
	local references = {}
	Array.forEach(transfers, function(transfer)
		Array.extendWith(references, References.fromStorageData(transfer.reference))
	end)
	references = References.makeUnique(references)

	return Array.map(references, References.createReferenceIconDisplay)
end

---@private
---@return string[]
function TransferRowWidget:_getClasses()
	local transfer = self.transfer

	if transfer.isRumour then
		return {'RumourRow'}
	end
	return {
		'divRow',
		'mainpage-transfer-' .. self:_getStatus()
	}
end

---@private
---@return string
function TransferRowWidget:_getStatus()
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

---@private
---@param role string?
---@return boolean
function TransferRowWidget:_isSpecialRole(role)
	if not role then return false end
	role = role:lower()
	return Table.includes(SPECIAL_ROLES, role)
end

---@return Widget?
function TransferRowWidget:status()
	local transfer = self.transfer

	if not transfer.isRumour then return end

	return createDivCell{
		classes = {'Status'},
		children = IconFa(RUMOUR_STATUS_TO_ICON_ARGS[transfer.confirmed])
	}
end

---@return Widget?
function TransferRowWidget:confidence()
	local transfer = self.transfer
	if not transfer.isRumour then return end

	local confidence = transfer.confidence

	return createDivCell{
		classes = {'Confidence', CONFIDENCE_TO_COLOR[confidence]},
		css = {['font-weight'] = 'bold'},
		children = confidence and String.upperCaseFirst(confidence) or nil
	}
end

---@return Widget
function TransferRowWidget:date()
	return createDivCell{
		classes = {'Date'},
		children = self.transfer.displayDate
	}
end

---@return Widget?
function TransferRowWidget:platform()
	local transfer = self.transfer
	if not transfer.platform then return end

	return createDivCell{
		classes = {'GameIcon'},
		children = transfer.platform
	}
end

---@return Widget
function TransferRowWidget:players()
	return createDivCell{
		classes = {'Name'},
		children = Array.map(self.transfer.players, function (player)
			return PlayerDisplay.BlockPlayer{player = player}
		end)
	}
end

---@return Widget
function TransferRowWidget:from()
	return self:_displayTeam{
		data = self.transfer.from,
		date = self.transfer.date,
		isOldTeam = true,
	}
end

---@private
---@param args {isOldTeam: boolean, date: string, data: {teams: string[], roles: string[]}}
---@return Widget
function TransferRowWidget:_displayTeam(args)
	local showTeamName = self.props.showTeamName
	local isOldTeam = args.isOldTeam
	local data = args.data
	local align = isOldTeam and 'right' or 'left'

	local function createTeamCell(props)
		return createDivCell{
			classes = {'Team', isOldTeam and 'OldTeam' or 'NewTeam'},
			css = showTeamName and {['text-align'] = align} or nil,
			children = props.children
		}
	end

	if not data.teams[1] and not data.roles[1] then
		return createTeamCell{
			children = self:_createRole{roles = {'&nbsp;None&nbsp;'}, marginDirection = align}
		}
	end

	---@param team string
	---@return Widget?
	local function teamDisplay(team)
		return OpponentDisplay.InlineTeamContainer{
			template = team,
			date = args.date,
			flip = isOldTeam,
			style = showTeamName and 'short' or 'icon'
		}
	end

	local teams = Array.map(data.teams, teamDisplay)

	local roleCell = self:_createRole{roles = data.roles, team = data.teams[1], marginDirection = align}

	return createTeamCell{
		children = WidgetUtil.collect(
			Array.interleave(teams, ' / '),
			#teams >= 1 and HtmlWidgets.Br{} or nil,
			roleCell
		)
	}
end

---@private
---@param props {roles: string[], team: string?, marginDirection: 'left'|'right'}
---@return Widget?
function TransferRowWidget:_createRole(props)
	if Logic.isEmpty(props.roles) then return end

	if Logic.isEmpty(props.team) then
		return HtmlWidgets.Span{
			css = {['font-style'] = 'italic'},
			children = Array.interleave(Array.filter(props.roles, Logic.isNotEmpty), '/')
		}
	end

	return HtmlWidgets.Span{
		css = {
			['font-style'] = 'italic',
			['font-size'] = '85%',
			['margin' .. props.marginDirection] = self.props.showTeamName and '60px' or nil,
		},
		children = WidgetUtil.collect(
			'(',
			Array.interleave(Array.filter(props.roles, Logic.isNotEmpty), '/'),
			')'
		)
	}
end

---@private
---@return Widget
function TransferRowWidget:_getTransferArrow()
	return IconFa{iconName = TRANSFER_STATUS_TO_ICON_NAME[self:_getStatus()]}
end

---@return Widget
function TransferRowWidget:icon()
	if not IconModule then
		return createDivCell{
			classes = {'Icon'},
			css = {width = '70px', ['font-size'] = 'larger'},
			children = self:_getTransferArrow()
		}
	end

	---@param iconInput string?
	---@return string|Widget
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

	local targetRoleIsSpecialRole = self:_isSpecialRole(self.transfer.to.roles[1])

	return createDivCell{
		classes = {'Icon'},
		css = {width = '70px'},
		children = WidgetUtil.collect(Array.interleave(
			Array.map(self.transfer.players, function (player)
				return HtmlWidgets.Fragment{children = {
					getIcon(player.icons[1]),
					'&nbsp;',
					self:_getTransferArrow(),
					'&nbsp;',
					getIcon(player.icons[2] or targetRoleIsSpecialRole and player.icons[1] or nil)
				}}
			end),
			HtmlWidgets.Br{}
		))
	}
end

---@return Widget
function TransferRowWidget:to()
	return self:_displayTeam{
		data = self.transfer.to,
		date = self.transfer.date,
		isOldTeam = false,
	}
end

---@return Widget
function TransferRowWidget:references()
	return createDivCell{
		classes = {'Ref'},
		children = Array.interleave(self.transfer.references, HtmlWidgets.Br{})
	}
end

return TransferRowWidget

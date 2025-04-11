---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/TeamHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')
local Widget = Lua.import('Module:Widget')
local Widgets = require('Module:Widget/All')

local Big = HtmlWidgets.Big
local Div = HtmlWidgets.Div

---@alias automatedHistoryMode 'ifEmpty'|'cleanup'|'both'|true|false?

---@class TeamHistoryWidget: Widget
---@operator call(table): TitleWidget
local TeamHistory = Class.new(Widget)

---@return Widget[]
function TeamHistory:render()
	local teamHistory = self:_getHistory()

	if Logic.isEmpty(teamHistory) then
		return {}
	end

	return {
		Widgets.Title{children = 'History'},
		Widgets.Center{children = {teamHistory}},
	}
end

function TeamHistory:_getHistory()
	local config = (Info.config.infoboxPlayer or {}).automatedHistory or {}

	---@type automatedHistoryMode
	local automatedHistoryMode = config.mode
	if not automatedHistoryMode or (Logic.isNotEmpty(self.props.manualInput) and automatedHistoryMode == 'ifEmpty') then
		return self.props.manualInput
	end

	--- can improve further once THA module is added to git (and cleaned up)...
	local automatedHistory = TeamHistoryAuto.results{
		player = self.props.player, -- string?
		hiderole = config.hideRole, --bool
		addlpdbdata = config.store, --bool
		specialRoles = config.specialRoles, --bool
		convertrole = config.convertRole, --bool
		cleanRoles = config.cleanRoles, -- string?
		iconModule = config.iconModule, -- string?
	}

	if Logic.isEmpty(self.props.manualInput) or (automatedHistoryMode ~= 'cleanup' and automatedHistoryMode ~= 'both') then
		return automatedHistory
	end

	if automatedHistoryMode == 'both' then
		return Div{children = {
			self.props.manualInput,
			automatedHistory,
		}}
	end

	return Div{children = {
		Div{children = {
			Big{
				classes = {'show-when-logged-in', 'navigation-not-searchable'},
				children = {'Automated History'},
			},
			automatedHistory,
		}},
		Div{children = {
			classes = {'show-when-logged-in', 'navigation-not-searchable'},
			Big{
				children = {'Manual History'},
			},
			self.props.manualInput,
		}},
	}}
end

return TeamHistory

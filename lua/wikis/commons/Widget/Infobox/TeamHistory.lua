---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local TeamHistoryAuto = Lua.import('Module:Infobox/Extension/TeamHistory/Auto')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Widgets = Lua.import('Module:Widget/All')

local Br = Html.Br
local Div = Html.Div
local Small = Html.Small

local DEFAULT_MODE = 'manual'

---@alias automatedHistoryMode
---|'manual' # always use manual input, never call THA
---|'automatic' # always use THA and ignore manual input
---|'manualPrio' # use manual input if present and THA else
---|'merge' # display both manual input and THA
---|'cleanup' # display THA and for logged in users manual input if present too

---@class TeamHistoryWidgetProps
---@field player string
---@field manualInput Renderable?

local Helpers = {}

---@param props TeamHistoryWidgetProps
---@return Renderable[]
local function TeamHistory(props)
	local teamHistory = Helpers._getHistory(props)

	if Logic.isEmpty(teamHistory) then
		return {}
	end

	return {
		Widgets.Title{children = 'History'},
		Widgets.Center{children = {teamHistory}},
	}
end

---@private
---@param props TeamHistoryWidgetProps
---@return Renderable?
function Helpers._getHistory(props)
	local config = (Info.config.infoboxPlayer or {}).automatedHistory or {}
	local manualInput = props.manualInput

	---@type automatedHistoryMode
	local mode = config.mode or DEFAULT_MODE
	if mode == DEFAULT_MODE or (Logic.isNotEmpty(manualInput) and mode == 'manualPrio') then
		return manualInput
	end

	local automatedHistory = TeamHistoryAuto.run{player = props.player, store = true}

	if Logic.isEmpty(manualInput) or (mode ~= 'cleanup' and mode ~= 'merge') then
		return automatedHistory
	end

	if Logic.isEmpty(automatedHistory) then
		return manualInput
	end

	if mode == 'merge' then
		return Div{children = {
			manualInput,
			automatedHistory,
		}}
	end

	return Div{children = {
		Div{children = {
			Div{
				classes = {'show-when-logged-in', 'navigation-not-searchable'},
				css = {['font-size'] = 'larger'},
				children = {'Automated History'},
			},
			automatedHistory,
		}},
		Div{
			classes = {'show-when-logged-in', 'navigation-not-searchable'},
			children = {
				Div{
					css = {['font-size'] = 'larger'},
					children = {'Manual History'},
				},
				Br{},
				Small{
					children = {'The below shown manual input only shows when logged in.'},
				},
				manualInput,
			},
		},
	}}
end

return Component.component(TeamHistory)

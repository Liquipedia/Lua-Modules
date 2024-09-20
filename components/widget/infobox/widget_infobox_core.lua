---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')
local WarningBox = require('Module:WarningBox')

local Widget = Lua.import('Module:Widget')
local Div = Lua.import('Module:Widget/Div')
local Fragment = Lua.import('Module:Widget/Fragment')

---@class Infobox: Widget
---@operator call(table): Infobox
---@field props table
local Infobox = Class.new(Widget, function(self, props)
	self.props = props
end)

---@param children string[]
---@return string
function Infobox:make(children)
	local firstInfobox = not Variables.varDefault('has_infobox')
	Variables.varDefine('has_infobox', 'true')

	local adbox = Div{classes = {'fo-nttax-infobox-adbox'}, children = {mw.getCurrentFrame():preprocess('<adbox />')}}
	local content = Div{classes = {'fo-nttax-infobox'}, children = children}
	local bottomContent = Div{children = self.props.bottomContent}

	return tostring(Fragment{children = {
		Div{
			classes = {
				'fo-nttax-infobox-wrapper',
				'infobox-' .. self.props.gameName:lower(),
				self.props.forceDarkMode and 'infobox-darkmodeforced' or nil,
			},
			children = {
				content,
				firstInfobox and adbox or nil,
				bottomContent,
			}
		},
		WarningBox.displayAll(self.props.warnings),
	}})
end

return Infobox

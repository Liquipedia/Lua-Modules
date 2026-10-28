---
-- @Liquipedia
-- page=Module:Widget/LazilyParsedTemplate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FeatureFlag = Lua.import('Module:FeatureFlag')
local Json = Lua.import('Module:Json')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class LazilyParsedTemplateProps
---@field template string
---@field [string|integer] any

---@param props LazilyParsedTemplateProps
---@return string
local function LazilyParsedTemplate(props)
	mw.incrementExpensiveFunctionCount()

	local templateArgs = Table.deepCopy(props)
	templateArgs.children = nil
	local template = Table.extract(templateArgs, 'template')

	templateArgs.dev = FeatureFlag.get('dev') or nil

	return Html.Div{
		classes = {'lp-lazily-called-template'},
		attributes = {['data-template'] = template},
		children = Json.stringify(templateArgs)
	}
end

return Component.component(LazilyParsedTemplate)

---
-- @Liquipedia
-- page=Module:Widget/EmptyPagePreview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Namespace = Lua.import('Module:Namespace')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local AmBox = Lua.import('Module:Widget/ArticleMessageBox')
local Component = Lua.import('Module:Widget/Component')
local EmptyTeamPagePreview = Lua.import('Module:Widget/EmptyPagePreview/Team')
local EmptyPersonPagePreview = Lua.import('Module:Widget/EmptyPagePreview/Person')
local Link = Lua.import('Module:Widget/Basic/Link')


---@param props EmptyTeamPagePreviewProps|{pageName: string}
---@return Renderable[]?
local EmptyPagePreview = function(props)
	if not Namespace.isMain() then
		return
	end

	local previewWarning = AmBox{
		image = 'Liquipedia logo.png',
		imageSize = '60px',
		text = {
			'You are currently viewing an automatically generated preview page. ',
			'In future, a page may be created for the topic if it meets the ',
			Link{link = 'Liquipedia:Notability_Guidelines', children = 'notability requirements'},
			'.',
		}
	}

	if TeamTemplate.exists(props.pageName) then
		return {
			previewWarning,
			EmptyTeamPagePreview(props)
		}
	end

	return {
		previewWarning,
		EmptyPersonPagePreview(props)
	}
end

return Component.component(EmptyPagePreview, {pageName = mw.title.getCurrentTitle().prefixedText})

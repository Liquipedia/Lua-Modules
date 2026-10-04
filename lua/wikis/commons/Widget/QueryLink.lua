---
-- @Liquipedia
-- page=Module:Widget/QueryLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class QueryLinkParameters
---@field mediawikiForm string
---@field form string
---@field template string?
---@field display Renderable
---@field queryArgs table?
---@field execute boolean?

---@param props QueryLinkParameters
---@return Renderable[]
local function QueryLink(props)
	---@param link string
	---@param class string
	---@return VNode
	local makeLinkDisplay = function(link, class)
		return Html.Span{
			classes = {class},
			children = Link{
				linktype = 'external',
				children = props.display,
				link = link,
			}
		}
	end

	-- mediawikiForm is only needed until lighthouse is fully ready
	---@return Renderable
	local makeMediawikiQueryLink = function()
		local form = assert(Logic.nilIfEmpty(props.mediawikiForm), 'Missing mediawikiForm input when building query link')
		---@type false|string
		local prefix = assert(Logic.nilIfEmpty(props.template) or not props.queryArgs,
			'Missing template input when building query link')

		local queryArgs = prefix and Table.map(props.queryArgs or {}, function(key, item)
			return prefix .. '[' .. key .. ']', item
		end) or {}

		local link = tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. form,
			queryArgs
		)) .. (props.execute and '&_run' or '')

		return makeLinkDisplay(link, 'hide-when-lighthouse')
	end

	---@return Renderable
	local makeLighthouseQueryLink = function()
		local form = assert(Logic.nilIfEmpty(props.form), 'Missing form input when building query link')

		local link = tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. form,
			props.queryArgs or {}
		))

		return makeLinkDisplay(link, 'hide-when-mediawiki')
	end

	return Html.Fragment{
		children = {
			makeMediawikiQueryLink(),
			makeLighthouseQueryLink()
		}
	}
end

return Component.component(QueryLink)

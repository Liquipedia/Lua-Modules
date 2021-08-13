local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local TypeUtil = require('Module:TypeUtil')

--[[
Utility module for working with starcraft and starcraft2 specific external
media links of matches. This includes the preview, lrthread, vodN, interviewN,
recap, and review params of both matches and games.
]]

local StarcraftMatchExternalLinks = {propTypes = {}}

-- List of supported external link parameters, in display order
StarcraftMatchExternalLinks.paramTypes = {
	'preview',
	'lrthread',
	'vod',
	'vodgame',
	'interview',
	'recap',
	'review',
}

StarcraftMatchExternalLinks.paramTypeIndexes = {}
for index, paramType in ipairs(StarcraftMatchExternalLinks.paramTypes) do
	StarcraftMatchExternalLinks.paramTypeIndexes[paramType] = index
end

--[[
Renders a single external link.

props.type: 'vod', 'preview', 'lrthread', or one of the allowed values in MatchExternalLinks.paramTypes
props.number: A number used to visually distinguish between multiple vods. Only number 1-9 have unique icons.
props.url:
]]
StarcraftMatchExternalLinks.propTypes.ExternalLink = {
	number = 'number?',
	type = 'string',
	url = 'string',
}

function StarcraftMatchExternalLinks.ExternalLink(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchExternalLinks.propTypes.ExternalLink)

	if props.type == 'preview' then
		return '[[File:Preview_Icon32.png|link=' .. props.url .. '|alt=preview|16px|Preview]] '
	end

	if props.type == 'lrthread' then
		return '[[File:LiveReport32.png|link=' .. props.url .. '|alt=lrthread|16px|Live Report Thread]] '
	end

	if props.type == 'vod' then
		if props.number and 1 <= props.number and props.number <= 9 then
			return '[[File:VOD Icon' .. props.number .. '.png|16px|link=' .. props.url .. '|Watch Game ' .. props.number .. ']] '
		else
			return '[[File:VOD Icon.png|link=' .. props.url .. '|16px|Watch VOD]] '
		end
	end

	if props.type == 'interview' then
		return '[[File:Int_Icon.png|link=' .. props.url .. '|16px|Interview]] '
	end

	if props.type == 'recap' then
		return '[[File:Reviews32.png|link=' .. props.url .. '|16px|Recap]] '
	end
	if props.type == 'review' then
		return '[[File:Reviews32.png|link=' .. props.url .. '|16px|Review]] '
	end

	error('Unsupported prop type ' .. tostring(props.type))
end

--[[
Extracts match media link relevant args from a generic args array, and
returns an array of link propss that can be rendered via
StarcraftMatchExternalLinks.MatchExternalLinks.
]]
function StarcraftMatchExternalLinks.extractFromArgs(args)
	local links = {}
	for paramName, url in pairs(args) do
		local type, number = tostring(paramName):match('^(%a+)(%d*)$')
		if StarcraftMatchExternalLinks.paramTypeIndexes[type] and url ~= '' then
			table.insert(links, {
				type = type,
				number = tonumber(number),
				url = url,
			})
		end
	end

	return links
end

function StarcraftMatchExternalLinks.extractFromMatch(match)
	local links = StarcraftMatchExternalLinks.extractFromArgs(match.links)

	if match.vod then
		table.insert(links, {type = 'vod', url = match.vod})
	end
	for gameIx, game in ipairs(match.games) do
		if game.vod then
			table.insert(links, {type = 'vod', number = gameIx, url = game.vod})
		end
	end

	return links
end

StarcraftMatchExternalLinks.propTypes.MatchExternalLinks = {
	links = TypeUtil.array(TypeUtil.struct(StarcraftMatchExternalLinks.propTypes.ExternalLink)),
}

function StarcraftMatchExternalLinks.MatchExternalLinks(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchExternalLinks.propTypes.MatchExternalLinks)
	local links = Array.sortBy(props.links, function(link)
		return {
			StarcraftMatchExternalLinks.paramTypeIndexes[link.type],
			-- Unnumbered vods appear before numbered ones
			link.number or -1,
		}
	end)

	local list = mw.html.create('span')
	for _, link in ipairs(links) do
		list:node(StarcraftMatchExternalLinks.ExternalLink(link))
	end
	return list
end

-- Called by Template:MatchExternalLink
function StarcraftMatchExternalLinks.TemplateMatchExternalLink(frame)
	local args = require('Module:Arguments').getArgs(frame)
	args.number = tonumber(args.number)
	return StarcraftMatchExternalLinks.ExternalLink(args)
end

return Class.export(StarcraftMatchExternalLinks)

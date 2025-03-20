local Json = require('Module:Json')

local Language = mw.language.new('en')

local p = {}

local DEV_NAMESPACE = 828

function p.store(frame)
	local args = frame.args

	local pagename = mw.title.getCurrentTitle().text

	-- In dev namespace.
	if mw.title.getCurrentTitle():inNamespace(DEV_NAMESPACE) then
		pagename = args.page
		args.page = nil
	end

	-- Read from pagename.
	_, _, mode, year, month = pagename:find('Ratings/(%a+)/(%d+)/(%d+)')
	year = tonumber(year)
	month = tonumber(month)

	local date = year .. '-' .. string.format('%02d', month) .. '-01 00:00:00'
	local prefix = 'Ratings_' .. mode .. '_' .. year .. '_' .. month .. '_'
	local extradata = Json.stringify({
		mode = mode,
		year = year,
		month = month,
	})

	local count = 0

	for id, elo in pairs(args) do
		-- Store.
		local uid = prefix .. id
		mw.ext.LiquipediaDB.lpdb_datapoint(
			uid,
			{
				date = date,
				type = 'Ratings',
				name = id,
				information = elo,
				extradata = extradata,
			}
		)

		count = count + 1
	end

	return 'This page is storing ' .. Language:formatNum(count) .. ' '
		.. mode .. ' ratings for ' .. Language:formatDate('F Y', date) .. '.'
end

return p

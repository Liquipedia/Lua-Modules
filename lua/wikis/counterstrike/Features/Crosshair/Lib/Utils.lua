local bit32 = require('bit32')

local Utils = {}

-- Converts a byte to his signed value
function Utils.signed(dec)
	if dec > 127 then
		return -1 * (bit32.band(bit32.bnot(dec),0xff)) -1
	end
	return dec
end

-- reverts signed function
function Utils.unsigned(dec)
	if dec < 0 then
		return bit32.band(bit32.bnot(dec* -1 -1),0xff)
	end
	return dec
end

-- 8 bit check sum its the sum of all bytes excluding the MSB and of the sum return only the LSB matter
function Utils.eightBitChecksum(bytes)
	local sum = 0
	for i = 2, #bytes do
		sum = sum + bytes[i]
	end
	return bit32.extract(sum,0,8)
end

function Utils.padStartTable(tbl, targetLength, value)
	local tableSize = 0
	for _ in pairs(tbl) do
		tableSize = tableSize + 1
	end
	while tableSize < targetLength do
		table.insert(tbl, 1, value)
		tableSize = tableSize + 1
	end
end

function Utils.padEndString(string,targetLength,padChar)
	while #string < targetLength do
		string = string .. padChar
	end
	return string
end

return Utils
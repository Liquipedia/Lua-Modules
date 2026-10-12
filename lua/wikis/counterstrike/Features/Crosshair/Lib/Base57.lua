
local bit32 = require('bit32')

local toByte, band, blshift, brshift = string.byte, bit32.band, bit32.lshift, bit32.rshift

local Base57 = {
    characterset = "ABCDEFGHJKLMNOPQRSTUVWXYZabcdefhijkmnopqrstuvwxyz23456789"
}

local function division(bytes)
	local quotient = {}
	local buffer = 0
	for i = 1, #bytes do
		if buffer < 57 then
			buffer = (blshift(buffer,8)) + bytes[i]
		end
		quotient[#quotient+1] = band(math.floor(buffer/57),0xff)
		buffer = math.fmod(buffer,57)
	end

	return quotient, buffer
end

--Checks if all elements of the table bytes are different from 0
local function checkAllBytesDiffZero(bytes)
	local sum = 0
	for i = 1, #bytes do
		sum = sum + bytes[i]
	end
	return sum ~= 0
end

function Base57.decode(s)
	-- b57charmap will map the internal value of a char in base57 alphabet to their position - 1 in base57chars
	-- 'A' ==> b57charmap[65] = 0
	local b57charmap = {};
	for i = 1, 57 do b57charmap[toByte(Base57.characterset, i)] = i - 1  end

	-- Can't decode invalid encoded string
	if string.find(s, "[^"..Base57.characterset.."]") then
		return nil
	end

	local bytes -- decoded number as an array of bytes (big endian)
	local d -- base57 digit, as an integer
	local b -- a byte in bytes
	local m -- a byte multiplied by 57 (used for product)
	local carry

	bytes = { b57charmap[toByte(s, #s)] } --init with most significant digit
	for i = #s - 1 ,1, -1  do
		-- multiply bytes by 57, then add next digit
		d = b57charmap[toByte(s, i)] -- next digit
		carry = 0
		-- multiply bytes by 57
		for j = #bytes, 1, -1 do
			b = bytes[j]
			m = b * 57 + carry
			b = band(m,0xff)
			carry = brshift(m, 8)
			bytes[j] = b
		end
		if carry > 0 then table.insert(bytes, 1, carry) end
		-- add next digit to bytes
		carry = d
		for j = #bytes, 1, -1 do
			b = bytes[j] + carry
			carry = brshift(b,8)
			bytes[j] = band(b , 0xff)
		end
		if carry > 0 then table.insert(bytes, 1, carry) end
	end

	return bytes
end

function Base57.encode(bytes)
	local remainder
	local s = ""
	-- Division will end when the bytes array is equal to 0
	while checkAllBytesDiffZero(bytes) do
		-- The division is made going though all bytes
		bytes, remainder = division(bytes)
		s = s .. Base57.characterset:sub(remainder+1, remainder+1)
	end

	return s
end


return Base57

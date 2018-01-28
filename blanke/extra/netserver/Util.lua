--[[
local sin = math.sin
local pi = math.pi
]]
function hex2rgb(hex)
	assert(type(hex) == "string", "hex2rgb: expected string, got "..type(hex).." ("..hex..")")
    hex = hex:gsub("#","")
    if(string.len(hex) == 3) then
        return {tonumber("0x"..hex:sub(1,1)) * 17, tonumber("0x"..hex:sub(2,2)) * 17, tonumber("0x"..hex:sub(3,3)) * 17}
    elseif(string.len(hex) == 6) then
        return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
    end
end

function lerp(a,b,amt)
	return a + (b-a) * amt
end

function ifndef(var_check, default)
	if var_check ~= nil then
		return var_check
	end
	return default
end

function random_range(n1, n2)
	return love.math.random(n1, n2)
end

function sinusoidal(min, max, speed, start_offset)
	local dist = (max - min)/2
	local offset = (min + max)/2
	local start = ifndef(start_offset, min) * (2*math.pi)
	return (100*math.sin(game_time * speed * math.pi + start)/100) * dist + offset;
end

love.graphics.resetColor = function()
	love.graphics.setColor(255, 255, 255, 255)
end

function string:starts(Start)
    return string.sub(self,1,string.len(Start))==Start
end

function string:ends(End)
	return string.sub(self,-string.len(End))==End
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end
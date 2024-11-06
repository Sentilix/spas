
Spas = select(2, ...)


--[[
	Convert a msg so first letter is uppercase, and rest as lower case.
--]]
function Spas:UCFirst(playername)
	if not playername then
		return ""
	end	

	-- Handles utf8 characters in beginning.. Ugly, but works:
	local offset = 2;
	local firstletter = string.sub(playername, 1, 1);
	if(not string.find(firstletter, '[a-zA-Z]')) then
		firstletter = string.sub(playername, 1, 2);
		offset = 3;
	end;

	return string.upper(firstletter) .. string.lower(string.sub(playername, offset));
end

function Spas:splitString(string, separator)
	local worktable = { };
	if string then
		separator = separator or "/";

		for str in string.gmatch(string, "([^"..separator.."]+)") do
			table.insert(worktable, str);
		end;
	end;
	return worktable;
end;

function Spas:trimLeft(str)
	local _, _, result = string.find(str, "%s*(.+)");
	return result;
end;

function Spas:trimRight(str)
	local _, _, result = string.find(str, "(.+%S)%s*");
	return result;
end;

function Spas:trim(str)
	local _, _, result = string.find(str, "%s*(%S*.*%S)%s*");
	return result;
end;

function Spas:clone(table)
	local result = { }
	for key, value in next, table do
		result[key] = value;
	end;
	return result;
end;

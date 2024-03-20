AddCSLuaFile()

--[[
	Easy way to set up Primary and Secondary tables
]]

function SWEP:SetupAmmo(key, data)
	local ammo_table = self[key]
	if not istable(ammo_table) then return end

	for k, v in next, data do
		ammo_table[k] = v
	end
end

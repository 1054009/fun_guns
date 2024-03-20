AddCSLuaFile()

AccessorFunc(SWEP, "m_bInPrimaryFire", "InPrimaryFire", FORCE_BOOL)
AccessorFunc(SWEP, "m_bInSecondaryFire", "InSecondaryFire", FORCE_BOOL)
AccessorFunc(SWEP, "m_TraceResult", "TraceResult")
AccessorFunc(SWEP, "m_TraceData", "TraceData")
AccessorFunc(SWEP, "m_iRandomSeed", "RandomSeed", FORCE_NUMBER)

--[[
	Safe way to get the owner
]]

function SWEP:TryOwner(function_name, ...)
	local owner = self:GetOwner()

	if not IsValid(owner) then
		return nil
	end

	local try_function = owner[function_name]

	if not isfunction(try_function) then
		return owner
	end

	return owner, try_function(owner, ...)
end

--[[
	Quick way to get fire information
]]

function SWEP:EitherFireMode(primary, secondary, fallback)
	if self:GetInPrimaryFire() then return primary end
	if self:GetInSecondaryFire() then return secondary end

	return fallback
end

function SWEP:GetCurrentFireTable()
	return self:EitherFireMode(self.Primary, self.Secondary, nil)
end

function SWEP:GetFireAmmoType()
	local fire_table = self:GetCurrentFireTable()
	if not fire_table then return -1 end

	return game.GetAmmoID(fire_table.Ammo)
end

--[[
	Quick way to access ammo information
]]

function SWEP:OwnerSupportsAmmo()
	local owner, is_player = self:TryOwner("IsPlayer")

	if not owner or not is_player then
		-- NPCs don't have ammo capacities
		return false
	end

	return owner
end

function SWEP:GetPrimaryReserveAmmo()
	local owner = self:OwnerSupportsAmmo()
	if not owner then return 9999 end

	return self:Ammo1() -- Just using Ammo1 and Ammo2 is dangerous because of NPCs
end

function SWEP:GetSecondaryReserveAmmo()
	local owner = self:OwnerSupportsAmmo()
	if not owner then return 9999 end

	return self:Ammo2()
end

function SWEP:GetCurrentReserveAmmo()
	return self:EitherFireMode(self:GetPrimaryReserveAmmo(), self:GetSecondaryReserveAmmo(), 9999)
end

function SWEP:GivePrimaryAmmo(amount) -- Opposite of TakePrimaryAmmo for reloading purposes
	if self:Clip1() >= self:GetMaxClip1() then return end

	local cip = self:Clip1()
	local max_clip = self:GetMaxClip1()
	local new_amount = cip + amount

	if new_amount > max_clip then -- Add to reserve instead of overflowing the clip
		local owner = self:OwnerSupportsAmmo()

		local reserve = new_amount - max_clip
		new_amount = max_clip

		if owner then
			local current_reserve = self:GetPrimaryReserveAmmo()

			owner:SetAmmo(current_reserve + reserve, self:GetPrimaryAmmoType())
		end
	end

	self:SetClip1(new_amount)
end

function SWEP:GiveSecondaryAmmo(amount)
	if self:Clip2() >= self:GetMaxClip2() then return end

	local cip = self:Clip2()
	local max_clip = self:GetMaxClip2()
	local new_amount = cip + amount

	if new_amount > max_clip then
		local owner = self:OwnerSupportsAmmo()

		local reserve = new_amount - max_clip
		new_amount = max_clip

		if owner then
			local current_reserve = self:GetSecondaryReserveAmmo()

			owner:SetAmmo(current_reserve + reserve, self:GetSecondaryAmmoType())
		end
	end

	self:SetClip2(new_amount)
end

--[[
	Optimize tracelines
]]

function SWEP:SetupTraceTables()
	local td = {}

	local tr = {}
	self:SetTraceResult(tr)

	td.mask = MASK_SHOT
	td.mins = Vector(-1, -1, -1)
	td.maxs = Vector(1, 1, 1)
	td.output = tr
	td.filter = {}

	self:SetTraceData(td)

	return td
end

function SWEP:GetSafeTraceData()
	local td = self:GetTraceData()

	if not istable(td) then
		td = self:SetupTraceTables()
	end

	return td
end

function SWEP:EmptyTraceFilter()
	local td = self:GetSafeTraceData()

	local filter = td.filter
	for i = #filter, 1, -1 do
		table.remove(filter, i)
	end

	return filter
end

function SWEP:RunTrace(start_pos, end_pos)
	local owner = self:TryOwner()
	assert(owner, "Tried to use RunTrace with invalid owner")

	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use RunTrace outside of fire event")

	local eye_pos = owner:EyePos()

	if not isvector(start_pos) then
		start_pos = eye_pos
	end

	if not isvector(end_pos) then
		local forward = owner:GetForward()

		forward:Mul(fire_table.BulletDistance)
		forward:Add(eye_pos)

		end_pos = forward
	end

	local td = self:GetSafeTraceData()

	td.start = start_pos
	td.endpos = end_pos

	local filter = self:EmptyTraceFilter()

	table.insert(filter, self) -- Don't shoot yourself, loser
	table.insert(filter, owner)

	util.TraceHull(td)

	return self:GetTraceResult()
end

--[[
	Nice way to handle bullets
]]

function SWEP:GetRandomCRC()
	return tonumber(util.CRC(tostring({})))
end

function SWEP:CalculateBulletSpread(offset)
	if not isnumber(offset) then
		offset = 0
	end

	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use CalculateBulletSpread outside of fire event")

	math.randomseed(UnPredictedCurTime() + self:GetRandomSeed() + offset)

	local x = math.Rand(0, fire_table.BulletSpread)
	local y = math.Rand(0, fire_table.BulletSpread)

	return Vector(x, y)
end

function SWEP:GenerateBullet(bullet_data, bullet_index)
	local owner = self:TryOwner()
	assert(owner, "Tried to use GenerateBullet with invalid owner")

	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use GenerateBullet outside of fire event")

	if not istable(bullet_data) then
		bullet_data = {}
	end

	bullet_index = tonumber(bullet_index) or 1

	bullet_data.Damage = fire_table.BulletDamage
	bullet_data.Distance = fire_table.BulletDistance
	bullet_data.Num = 1
	bullet_data.AmmoType = fire_table.Ammo
	bullet_data.Dir = owner:GetForward()
	bullet_data.Src = owner:EyePos()
	bullet_data.IgnoreEntity = owner
	bullet_data.Spread = self:CalculateBulletSpread(bullet_index * math.pi)

	return bullet_data
end

function SWEP:FireBullet()
	local owner = self:TryOwner()
	assert(owner, "Tried to use FireBullet with invalid owner")

	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use FireBullet outside of fire event")

	local bullet_data = {}

	owner:LagCompensation(true)
		for bullet_index = 1, fire_table.BulletCount do
			self:GenerateBullet(bullet_data, bullet_index)

			owner:FireBullets(bullet_data)
		end
	owner:LagCompensation(false)
end

function SWEP:ApplyNextFireTime()
	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use ApplyNextFireTime outside of fire event")

	local apply_function = self:EitherFireMode(self.SetNextPrimaryFire, self.SetNextSecondaryFire)
	assert(apply_function, "Tried to use ApplyNextFireTime outside of fire event")

	apply_function(self, CurTime() + fire_table.FireInterval)
end

function SWEP:CalculateViewPunch()
	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use CalculateViewPunch outside of fire event")

	local view_punch = fire_table.ViewPunch

	local max_pitch, min_pitch = view_punch[1], view_punch[2]
	local min_yaw, max_yaw = view_punch[2], view_punch[3]

	local pitch = math.Rand(min_pitch, max_pitch)
	local yaw = math.Rand(min_yaw, max_yaw)

	return Angle(-pitch, yaw)
end

function SWEP:ApplyViewPunch()
	self:TryOwner("ViewPunch", self:CalculateViewPunch())
end

function SWEP:CalculateAimPunch()
	local fire_table = self:GetCurrentFireTable()
	assert(fire_table, "Tried to use CalculateAimPunch outside of fire event")

	local view_punch = fire_table.AimPunch

	local max_pitch, min_pitch = view_punch[1], view_punch[2]
	local min_yaw, max_yaw = view_punch[2], view_punch[3]

	local pitch = math.Rand(min_pitch, max_pitch)
	local yaw = math.Rand(min_yaw, max_yaw)

	return Angle(-pitch, yaw)
end

function SWEP:ApplyAimPunch()
	local owner, is_player = self:TryOwner("IsPlayer")
	if not owner or not is_player then return end

	local eye_angles = owner:EyeAngles()
	local aim_punch = self:CalculateAimPunch()

	eye_angles:Add(aim_punch)

	eye_angles.pitch = math.Clamp(math.NormalizeAngle(eye_angles.pitch), -89, 89)
	eye_angles.yaw = math.NormalizeAngle(eye_angles.yaw)
	eye_angles.roll = math.NormalizeAngle(eye_angles.roll)

	owner:SetEyeAngles(eye_angles)
end

--[[
	Quick way to shoot
]]

function SWEP:BasicFire()
	self:FireBullet()
	self:TakePrimaryAmmo(1)
	self:ApplyNextFireTime()

	self:ApplyAimPunch()
	self:ApplyViewPunch()

	return true
end

--[[
	Nice way to loop over entities in an area
]]

function SWEP:ForEntityInArea(origin, radius, callback, ...)
	if not isfunction(callback) then return end

	local excluded_ents = select("#", ...)

	if excluded_ents > 0 then -- Setup excluded table
		local excluded_amount = excluded_ents
		excluded_ents = {}

		for i = 1, excluded_amount do
			excluded_ents[select(i, ...)] = true
		end
	end

	local entities = ents.FindInSphere(origin, radius)

	for i = 1, #entities do
		local entity = entities[i]

		if excluded_ents[entity] then continue end
		if not IsValid(entity) then continue end

		callback(self, entity)
	end
end

--[[
	Kind of silly that GetConVarNumber was deprecated, it's pretty useful
]]

function SWEP:GetConVarNumber(name, default)
	local convar = GetConVar(name)

	if not convar then
		return default
	end

	return convar:GetFloat()
end

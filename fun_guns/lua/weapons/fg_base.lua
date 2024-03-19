--[[
	Setup variables
]]

SWEP.Category = "Fun Guns"

SWEP.Spawnable = false

SWEP.AdminOnly = false

SWEP.PrintName = "Fun Gun Base"

SWEP.Base = "weapon_base"

SWEP.Author = ""

SWEP.Contact = "https://mn.gov/mnddc/parallels2/pdf/60s/63/63-AHG-NARC.pdf"

SWEP.Purpose = "Fun Guns"

SWEP.Instructions = "Point and click"

SWEP.ViewModel = "models/weapons/c_pistol.mdl"

SWEP.ViewModelFOV = 62

SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Slot = 0

if not istable(SWEP.Primary) then
	SWEP.Primary = {}
end

SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.ClipSize = 10

SWEP.Primary.DefaultClip = 10

SWEP.Primary.Automatic = false

SWEP.Primary.Damage = 1

SWEP.Primary.Spread = 1

if not istable(SWEP.Secondary) then
	SWEP.Secondary = {}
end

SWEP.Secondary.Ammo = ""

SWEP.Secondary.ClipSize = 0

SWEP.Secondary.DefaultClip = 0

SWEP.Secondary.Automatic = false

SWEP.Secondary.Damage = 1

SWEP.Secondary.Spread = 1

SWEP.UseHands = true

SWEP.DisableDuplicator = false

--[[
	Custom variables
]]

SWEP.PrimaryFireInterval = 0.1

SWEP.UsesPrimaryAmmo = true

SWEP.SecondaryFireInterval = 0.1

SWEP.UsesSecondaryAmmo = false

SWEP.BulletDistance = 56756

AccessorFunc(SWEP, "m_iUnsharedSeed", "UnsharedSeed", FORCE_NUMBER)

SWEP.Bullet = {}

SWEP.FIRE_MODE_NONE = 0

SWEP.FIRE_MODE_PRIMARY = 1

SWEP.FIRE_MODE_SECONDARY = 2

--[[
	Global functions
]]

function SWEP:Initialize()
	self.TraceResult = {} -- Optimize traces

	self.TraceData = {}

	self.TraceData.output = self.TraceResult
	self.TraceData.mins = Vector(-1, -1, -1)
	self.TraceData.maxs = Vector(1, 1, 1)
	self.TraceData.mask = MASK_SHOT
	self.TraceData.filter = {}

	if not isnumber(self:GetUnsharedSeed()) then
		-- Fix it!
		self:SetUnsharedSeed(tonumber(util.CRC(tostring({}))))
	end

	if CLIENT then
		local viewmodel_fov = GetConVar("viewmodel_fov")

		if viewmodel_fov then
			self.ViewModelFOV = viewmodel_fov:GetInt()
		end
	end

	self:PostInitialize()
end

function SWEP:PostInitialize()

end

function SWEP:OnRemove()

end

function SWEP:GetNextPrimaryFireTime()
	return CurTime() + self.PrimaryFireInterval
end

function SWEP:GetNextSecondaryFireTime()
	return CurTime() + self.SecondaryFireInterval
end

function SWEP:GetUsesPrimaryAmmo()
	return self.UsesPrimaryAmmo
end

function SWEP:SetUsesPrimaryAmmo(state)
	self.UsesPrimaryAmmo = tobool(state)
end

function SWEP:GetUsesSecondaryAmmo()
	return self.UsesSecondaryAmmo
end

function SWEP:SetUsesSecondaryAmmo(state)
	self.UsesSecondaryAmmo = tobool(state)
end

function SWEP:CanPrimaryAttack()
	if not IsFirstTimePredicted() then
		return false
	end

	if CurTime() < self:GetNextPrimaryFire() then
		return false
	end

	if self:GetUsesPrimaryAmmo() and self:Clip1() <= 0 then
		return false
	end

	return true
end

function SWEP:CanSecondaryAttack()
	if not IsFirstTimePredicted() then
		return false
	end

	if CurTime() < self:GetNextSecondaryFire() then
		return false
	end

	if self:GetUsesSecondaryAmmo() and self:Clip2() <= 0 then
		return false
	end

	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	if fg_base.IsSinglePlayer then
		self:CallOnClient("PrimaryAttack")
	end

	self.m_bInPrimaryAttack = true
		if self:DoPrimaryAttack() then
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		end
	self.m_bInPrimaryAttack = false
end

function SWEP:DoPrimaryAttack()
	return false
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end

	if fg_base.IsSinglePlayer then
		self:CallOnClient("SecondaryAttack")
	end

	self.m_bInSecondaryAttack = true
		if self:DoSecondaryAttack() then
			self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
		end
	self.m_bInSecondaryAttack = false
end

function SWEP:DoSecondaryAttack()
	return false
end

function SWEP:GetCurrentFireMode()
	if self.m_bInPrimaryAttack then
		return self.FIRE_MODE_PRIMARY
	elseif self.m_bInSecondaryAttack then
		return self.FIRE_MODE_SECONDARY
	else
		return self.FIRE_MODE_NONE
	end
end

function SWEP:ReturnFireMode(primary, secondary, default)
	local fire_mode = self:GetCurrentFireMode()

	if fire_mode == self.FIRE_MODE_PRIMARY then
		return primary
	elseif fire_mode == self.FIRE_MODE_SECONDARY then
		return secondary
	else
		return default
	end
end

function SWEP:GetCurrentAmmoType()
	return self:ReturnFireMode(self:GetPrimaryAmmoType(), self:GetSecondaryAmmoType(), -1)
end

function SWEP:GetCurrentFireTable()
	return self:ReturnFireMode(self.Primary, self.Secondary, nil)
end

function SWEP:EmptyTraceFilter() -- Faster than table.Empty
	local filter = self.TraceData.filter

	for i = #filter, 1, -1 do
		table.remove(filter, i)
	end

	return filter
end

function SWEP:RunTrace(end_position)
	local owner = self:GetOwner()
	if not IsValid(owner) then
		ErrorNoHaltWithStack("Tried to trace with no owner!")
		return {}
	end

	if not isvector(end_position) then
		local forward = owner:GetForward()

		forward:Mul(self.BulletDistance)
		forward:Add(self:GetPos())

		end_position = forward
	end

	self.TraceData.start = owner:EyePos()
	self.TraceData.endpos = end_position

	local filter = self:EmptyTraceFilter()

	filter[#filter + 1] = self -- Don't shoot yourself, loser
	filter[#filter + 1] = owner

	util.TraceHull(self.TraceData)

	return self.TraceResult
end

function SWEP:RandomBulletSpread(fire_table)
	if not istable(fire_table) then
		fire_table = self:GetCurrentFireTable()

		if not istable(fire_table) then
			return Vector()
		end
	end

	math.randomseed(UnPredictedCurTime() + self:GetUnsharedSeed())

	local x = math.Rand(0, fire_table.Spread)
	local y = math.Rand(0, fire_table.Spread)

	return Vector(x, y)
end

function SWEP:FireBullet(amount, direction, spread, damage, ammo_type)
	local owner = self:GetOwner()
	if not IsValid(owner) then
		error("Tried to shoot with no owner!")
		return
	end

	local fire_table = self:GetCurrentFireTable()
	if not istable(fire_table) then
		error("Tried to shoot outside of an attack function!")
		return
	end

	local bullet = self.Bullet

	bullet.Num = tonumber(amount) or 1
	bullet.Src = owner:EyePos()
	bullet.Dir = isvector(direction) and direction or owner:GetForward()
	bullet.Spread = isvector(spread) and spread or self:RandomBulletSpread()
	bullet.Damage = tonumber(damage) or fire_table.Damage
	bullet.Force = bullet.Damage * 0.5
	bullet.AmmoType = isnumber(ammo_type) and ammo_type or self:GetCurrentAmmoType()
	bullet.IgnoreEntity = owner

	owner:LagCompensation(true)
		owner:FireBullets(bullet)
	owner:LagCompensation(false)
end

--[[
	Helper functions
]]

fg_base = istable(fg_base) and fg_base or {}

fg_base.IsSinglePlayer = game.SinglePlayer()

function fg_base.SetupSWEP(swep, name)
	swep.Category = "Fun Guns"

	swep.Spawnable = true

	swep.PrintName = name

	return baseclass.Get(swep.Base)
end

function fg_base.ForEntitiesInRadius(origin, radius, callback)
	local entities = ents.FindInSphere(origin, radius)

	for i = 1, #entities do
		if IsValid(entities[i]) then
			callback(entities[i])
		end
	end
end

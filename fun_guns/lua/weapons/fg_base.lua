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

SWEP.ViewModel = "models/weapons/v_pistol.mdl"

SWEP.ViewModelFOV = 62

SWEP.Slot = 0

if not istable(SWEP.Primary) then
	SWEP.Primary = {}
end

SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.ClipSize = 10

SWEP.Primary.DefaultClip = 10

SWEP.Primary.Automatic = false

SWEP.Primary.Damage = 1

if not istable(SWEP.Secondary) then
	SWEP.Secondary = {}
end

SWEP.Secondary.Ammo = ""

SWEP.Secondary.ClipSize = 0

SWEP.Secondary.DefaultClip = 0

SWEP.Secondary.Automatic = false

SWEP.Secondary.Damage = 1

SWEP.DisableDuplicator = false

--[[
	Custom variables
]]

SWEP.PrimaryFireInterval = 0.1

SWEP.UsesPrimaryAmmo = true

SWEP.SecondaryFireInterval = 0.1

SWEP.UsesSecondaryAmmo = false

SWEP.BulletDistance = 56756

SWEP.BulletSpread = 1

AccessorFunc(SWEP, "m_iUnsharedSeed", "UnsharedSeed", FORCE_NUMBER)

SWEP.Bullet = {}

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

	if CLIENT then
		-- Unshared seed isn't networked, obviously
		self:SetUnsharedSeed(tonumber(util.CRC(tostring({}))))
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

function SWEP:GetCurrentAmmoType()
	if self.m_bInPrimaryAttack then
		return self:GetPrimaryAmmoType()
	elseif self.m_bInSecondaryAttack then
		return self:GetSecondaryAmmoType()
	else
		return -1
	end
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

	if not isvector(end_position) then
		local forward = owner:EyeAngles():Forward()

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

function SWEP:RandomBulletSpread()
	math.randomseed(self:GetUnsharedSeed())

	local x = math.Rand(-self.BulletSpread, self.BulletSpread)
	local y = math.Rand(-self.BulletSpread, self.BulletSpread)
	local z = math.Rand(-self.BulletSpread, self.BulletSpread)

	return Vector(x, y, z)
end

function SWEP:FireBullet(amount, direction, spread, damage, ammo_type)
	local owner = self:GetOwner()
	local bullet = self.Bullet

	bullet.Num = tonumber(amount) or 1
	bullet.Src = owner:EyePos()
	bullet.Dir = isvector(direction) and direction or owner:GetForward()
	bullet.Spread = isvector(spread) and spread or self:RandomBulletSpread()
	bullet.Damage = tonumber(damage) or self.Primary.Damage
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

	return baseclass.Get("fg_base")
end

function fg_base.ForEntitiesInRadius(origin, radius, callback)
	local entities = ents.FindInSphere(origin, radius)

	for i = 1, #entities do
		if IsValid(entities[i]) then
			callback(entities[i])
		end
	end
end

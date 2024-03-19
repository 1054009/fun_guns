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

SWEP.Primary.BulletCount = 1

SWEP.Primary.Damage = 1

SWEP.Primary.Spread = 1

SWEP.Primary.VerticalViewPunch = 1

SWEP.Primary.HorizontalViewPunch = 1

SWEP.Primary.Enabled = true

if not istable(SWEP.Secondary) then
	SWEP.Secondary = {}
end

SWEP.Secondary.Ammo = ""

SWEP.Secondary.ClipSize = 0

SWEP.Secondary.DefaultClip = 0

SWEP.Secondary.Automatic = false

SWEP.Secondary.BulletCount = 1

SWEP.Secondary.Damage = 1

SWEP.Secondary.Spread = 1

SWEP.Secondary.VerticalViewPunch = 1

SWEP.Secondary.HorizontalViewPunch = 1

SWEP.Secondary.Enabled = false

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

	self.m_iSpreadSeed = tonumber(util.CRC(tostring({})))

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

function SWEP:Think()
	local result = self:OnThink()

	if result == true then
		return true
	end
end

function SWEP:OnThink()

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

function SWEP:TakeAmmo(amount, ammo_type)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	ammo_type = tonumber(ammo_type) or -1

	local take_function = self:ReturnFireMode(self.TakePrimaryAmmo, self.TakeSecondaryAmmo)

	if not isfunction(take_function) then
		take_function = self:ReturnAmmoType(ammo_type, self.TakePrimaryAmmo, self.TakeSecondaryAmmo)

		if not isfunction(take_function) then
			return
		end
	end

	amount = tonumber(amount) or 0

	if owner:IsPlayer() and amount < 0 then -- If we try to take a negative amount of ammo, try to take ammo from the reserve
		ammo_type = ammo_type or self:GetCurrentAmmoType()
		local magazine = self:GetReserveAmmo(ammo_type)

		if magazine > 0 then
			local fixed_amount = math.abs(amount)

			fixed_amount = math.min(fixed_amount, magazine)
			magazine = magazine - fixed_amount

			owner:SetAmmo(magazine, ammo_type)
		else
			return
		end
	end

	take_function(self, amount)
end

function SWEP:GetClipAmmo(ammo_type)
	return self:ReturnAmmoType(ammo_type, self:Clip1(), self:Clip2(), 0)
end

function SWEP:GetReserveAmmo(ammo_type)
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then
		return 9999
	end

	ammo_type = self:ReturnAmmoType(ammo_type, self:GetPrimaryAmmoType(), self:GetSecondaryAmmoType(), -1)
	if ammo_type == -1 then
		return 0
	end

	return owner:GetAmmoCount(ammo_type)
end

function SWEP:PrimaryAttackEnabled()
	return self.Primary.Enabled
end

function SWEP:SecondaryAttackEnabled()
	return self.Secondary.Enabled
end

function SWEP:CanPrimaryAttack()
	if not IsFirstTimePredicted() then
		return false
	end

	if not self:PrimaryAttackEnabled() then
		return false
	end

	if CurTime() < self:GetNextPrimaryFire() then
		return false
	end

	if self:GetUsesPrimaryAmmo() and self:GetClipAmmo(self:GetPrimaryAmmoType()) <= 0 then
		return false
	end

	return true
end

function SWEP:CanSecondaryAttack()
	if not IsFirstTimePredicted() then
		return false
	end

	if not self:SecondaryAttackEnabled() then
		return false
	end

	if CurTime() < self:GetNextSecondaryFire() then
		return false
	end

	if self:GetUsesSecondaryAmmo() and self:GetClipAmmo(self:GetSecondaryAmmoType()) <= 0 then
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

			local owner = self:GetOwner()
			if IsValid(owner) then
				owner:SetAnimation(PLAYER_ATTACK1)

				if owner:IsPlayer() then
					owner:ViewPunch(self:CalculateViewPunch())
				end
			end
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

			local owner = self:GetOwner()
			if IsValid(owner) then
				owner:SetAnimation(PLAYER_ATTACK1)
			end
		end
	self.m_bInSecondaryAttack = false
end

function SWEP:DoSecondaryAttack()
	return false
end

function SWEP:CanReload()
	return true
end

function SWEP:Reload()
	if not IsFirstTimePredicted() then return end -- CanReload is for override
	if not self:CanReload() then return end

	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:SetAnimation(PLAYER_RELOAD)
	end

	self:SendWeaponAnim(ACT_VM_RELOAD)

	self:DoReload()
end

function SWEP:DoReload()
	baseclass.Get("weapon_base").Reload(self)
end

function SWEP:GetCurrentFireMode()
	if self.m_bInPrimaryAttack then
		return fg_base.FIRE_MODE_PRIMARY
	elseif self.m_bInSecondaryAttack then
		return fg_base.FIRE_MODE_SECONDARY
	else
		return fg_base.FIRE_MODE_NONE
	end
end

function SWEP:ReturnFireMode(primary, secondary, default)
	local fire_mode = self:GetCurrentFireMode()

	if fire_mode == fg_base.FIRE_MODE_PRIMARY then
		return primary
	elseif fire_mode == fg_base.FIRE_MODE_SECONDARY then
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

function SWEP:ReturnAmmoType(ammo_type, primary, secondary, default)
	if ammo_type == self:GetPrimaryAmmoType() then
		return primary
	elseif ammo_type == self:GetSecondaryAmmoType() then
		return seconary
	else
		return default
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

function SWEP:GetSpreadSeed()
	return self.m_iSpreadSeed
end

function SWEP:RandomBulletSpread(bullet_index)
	local fire_table = self:GetCurrentFireTable()
	if not istable(fire_table) then
		return Vector()
	end

	bullet_index = tonumber(bullet_index) or 0

	math.randomseed(SysTime() + self:GetSpreadSeed() + bullet_index)

	local x = math.Rand(0, fire_table.Spread)
	local y = math.Rand(0, fire_table.Spread)

	return Vector(x, y)
end

function SWEP:FireBullet(amount, direction, damage, ammo_type)
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

	amount = tonumber(amount) or fire_table.BulletCount

	local bullet = self.Bullet
	bullet.Num = 1
	bullet.Src = owner:EyePos()
	bullet.Dir = isvector(direction) and direction or owner:GetForward()
	bullet.Damage = tonumber(damage) or fire_table.Damage
	bullet.Force = bullet.Damage * 0.5
	bullet.AmmoType = isnumber(ammo_type) and ammo_type or self:GetCurrentAmmoType()
	bullet.IgnoreEntity = owner

	for i = 1, amount do
		bullet.Spread = self:RandomBulletSpread(i)

		owner:LagCompensation(true)
			owner:FireBullets(bullet)
		owner:LagCompensation(false)
	end
end

function SWEP:UnpackPunch(punch)
	if isnumber(punch) then
		return punch
	elseif istable(punch) and isnumber(punch[1]) and isnumber(punch[2]) then
		return math.Rand(punch[1], punch[2])
	else
		return tonumber(punch) or 0
	end
end

function SWEP:CalculateViewPunch()
	local fire_table = self:GetCurrentFireTable()
	if not istable(fire_table) then
		return Angle()
	end

	local vertical_punch = self:UnpackPunch(fire_table.VerticalViewPunch)
	local horizontal_punch = self:UnpackPunch(fire_table.HorizontalViewPunch)

	return Angle(-vertical_punch, horizontal_punch)
end

function SWEP:SetNextThinkTime(time)
	self:NextThink(time)

	if CLIENT then
		self:SetNextClientThink(time)
	end

	-- https://github.com/Facepunch/garrysmod-issues/issues/3269
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)
end

--[[
	Helper functions
]]

fg_base = istable(fg_base) and fg_base or {}

fg_base.IsSinglePlayer = game.SinglePlayer()

fg_base.DontIgniteClasses = {
	["gmod_hands"] = true,
	["predicted_viewmodel"] = true,
	["viewmodel"] = true
}

fg_base.FIRE_MODE_NONE = 0

fg_base.FIRE_MODE_PRIMARY = 1

fg_base.FIRE_MODE_SECONDARY = 2

fg_base.RELOAD_STATE_START = 0

fg_base.RELOAD_STATE_ONGOING = 1

fg_base.RELOAD_STATE_FINISHED = 2

fg_base.ATTACK_STATE_START = 0

fg_base.ATTACK_STATE_ONGOING = 1

fg_base.ATTACK_STATE_FINISHED = 2

function fg_base.SetupSWEP(swep, name)
	swep.Category = "Fun Guns"

	swep.Spawnable = true

	swep.PrintName = name

	return baseclass.Get(swep.Base)
end

function fg_base.ForEntitiesInRadius(origin, radius, callback, ...)
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
		if excluded_ents and excluded_ents[entities[i]] then continue end
		if not IsValid(entities[i]) then continue end

		callback(entities[i])
	end
end

function fg_base.CanIgniteEntity(entity)
	if not IsValid(entity) then return false end

	if entity:IsWeapon() then return false end
	if fg_base.DontIgniteClasses[entity:GetClass()] then return false end

	return true
end

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

if not istable(SWEP.Secondary) then
	SWEP.Secondary = {}
end

SWEP.Secondary.Ammo = "Pistol"

SWEP.Secondary.ClipSize = 0

SWEP.Secondary.DefaultClip = 0

SWEP.Secondary.Automatic = false

SWEP.DisableDuplicator = false

--[[
	Custom variables
]]

SWEP.PrimaryFireInterval = 0.1

SWEP.UsesPrimaryAmmo = true

SWEP.SecondaryFireInterval = 0.1

SWEP.UsesSecondaryAmmo = false

SWEP.BulletDistance = 56756

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

end

function SWEP:SecondaryAttack()

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

--[[
	Helper functions
]]

fg_base = istable(fg_base) and fg_base or {}

function fg_base.SetupSWEP(swep, name)
	swep.Category = "Fun Guns"

	swep.Spawnable = true

	swep.PrintName = name

	return baseclass.Get("fg_base")
end

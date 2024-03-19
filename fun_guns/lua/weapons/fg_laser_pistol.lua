SWEP.Base = "fg_base"

local base_class = fg_base.SetupSWEP(SWEP, "Laser Pistol")

SWEP.Primary.ClipSize = 18

SWEP.Primary.DefaultClip = 18

SWEP.Primary.Damage = 50

SWEP.Primary.Spread = 0.1

SWEP.Primary.VerticalViewPunch = 6

SWEP.Primary.HorizontalViewPunch = { -5, 5 }

SWEP.PrimaryFireInterval = 0.2

function SWEP:PostEntityFireBullets(entity, data)
	local tr = data.Trace

	if tr.Hit then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end
		if entity ~= owner or owner:GetActiveWeapon() ~= self then return end

		local effect_data = EffectData()

		effect_data:SetStart(tr.StartPos)
		effect_data:SetEntity(self)
		effect_data:SetAttachment(1)
		effect_data:SetOrigin(tr.HitPos)

		util.Effect("laser", effect_data)
	end
end

function SWEP:PostInitialize()
	self:SetHoldType("pistol")

	if CLIENT then
		hook.Add("PostEntityFireBullets", self, self.PostEntityFireBullets)
	end
end

function SWEP.IgniteCallback(target)
	if not fg_base.CanIgniteEntity(target) then return end

	target:Ignite(5, 30)
end

function SWEP:DoPrimaryAttack()
	if SERVER then
		local tr = self:RunTrace()

		if tr.Hit then
			fg_base.ForEntitiesInRadius(tr.HitPos, 50, self.IgniteCallback, self:GetOwner())
		end
	end

	self:FireBullet()
	self:TakeAmmo(1)
	self:SetNextPrimaryFire(self:GetNextPrimaryFireTime())

	return true
end

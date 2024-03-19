SWEP.Base = "fg_base"

local base_class = fg_base.SetupSWEP(SWEP, "Laser Pistol")

SWEP.PrimaryFireInterval = 2

function SWEP:PostInitialize()
	self:SetHoldType("pistol")
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local tr = self:RunTrace()

	if tr.Hit then
		local effect_data = EffectData()

		effect_data:SetStart(tr.StartPos)
		effect_data:SetEntity(self)
		effect_data:SetAttachment(1)
		effect_data:SetOrigin(tr.HitPos)

		util.Effect("laser", effect_data)
	end

	self:FireBullet(nil, nil, vector_origin, 1234)
	self:TakePrimaryAmmo(1)
	self:SetNextPrimaryFire(self:GetNextPrimaryFireTime())
end

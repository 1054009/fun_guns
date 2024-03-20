SWEP.Base = "weapon_fg_base"
SWEP.PrintName = "Laser Pistol"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Category = "Fun Guns"
SWEP.Slot = 1

SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

include("weapon_fg_base/sh_ammo.lua")

SWEP:SetupAmmo("Primary",
{
	Ammo = "Pistol",
	ClipSize = 18,
	DefaultClip = 18,

	ViewPunch = { 6, 0, -5, 5 },
	AimPunch = { 1, 0, -0.5, 0.5 },
	BulletCount = 1,
	BulletSpread = 0.05,
	BulletDamage = 50,
	FireInterval = 0.2,
	UsesAmmo = true,
	Enabled = true
})

SWEP.IgniteWhitelist = {
	gmod_hands = true,
	predicted_viewmodel = true,
	viewmodel = true
}

function SWEP:IgniteCallback(entity)
	if self.IgniteWhitelist[entity:GetClass()] then return end -- Don't engulf them with their own viewmodels and weapons
	if entity:IsWeapon() then return end

	entity:Ignite(5)
end

function SWEP:PostBulletFired(bullet_data)
	local tr = bullet_data.Trace

	if tr.Hit then
		-- Laser effect
		local effect = EffectData()

		effect:SetOrigin(tr.HitPos)
		effect:SetStart(tr.StartPos)
		effect:SetAttachment(1)
		effect:SetEntity(self)

		util.Effect("ToolTracer", effect)

		-- Light it up
		if SERVER then
			self:ForEntityInArea(tr.HitPos, 50, self.IgniteCallback, self:GetOwner())
		end
	end
end

function SWEP:OnPrimaryAttack()
	return self:BasicFire()
end

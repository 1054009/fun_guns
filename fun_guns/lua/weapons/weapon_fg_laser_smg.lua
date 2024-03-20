SWEP.Base = "weaoon_fg_laser_pistol"
SWEP.PrintName = "Laser SMG"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Category = "Fun Guns"
SWEP.Slot = 2

SWEP.ViewModel = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"

include("weapon_fg_base/sh_ammo.lua")

SWEP:SetupAmmo("Primary",
{
	Ammo = "SMG1",
	ClipSize = 45,
	DefaultClip = 45,
	Automatic = true,

	ViewPunch = { 1, 0, -1, 1 },
	AimPunch = { 0.5, 0, -0.25, 0.25 },
	BulletCount = 1,
	BulletSpread = 0.2,
	BulletDamage = 80,
	FireInterval = 0.1,
	UsesAmmo = true,
	Enabled = true
})

SWEP:SetupAmmo("Secondary",
{
	Ammo = "SMG1",
	ClipSize = 45,
	DefaultClip = 45,
	Automatic = true,

	BulletCount = 1,
	BulletSpread = 0.2,
	BulletDamage = 1,
	FireInterval = 0.01,
	UsesAmmo = true,
	Enabled = true
})

function SWEP:OnInitialize()
	self:SetHoldType("smg")
end

function SWEP:OnSecondaryAttack()
	return self:BasicFire()
end

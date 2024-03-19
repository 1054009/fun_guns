SWEP.Base = "fg_laser_pistol"

local base_class = fg_base.SetupSWEP(SWEP, "Laser Shotgun")

SWEP.ViewModel = "models/weapons/c_shotgun.mdl"

SWEP.WorldModel = "models/weapons/w_shotgun.mdl"

SWEP.Primary.Ammo = "Buckshot"

SWEP.Primary.ClipSize = 6

SWEP.Primary.DefaultClip = 6

SWEP.Primary.BulletCount = 7

SWEP.Primary.Damage = 1234

SWEP.Primary.Spread = 0.5

SWEP.Primary.VerticalViewPunch = 12

SWEP.Primary.HorizontalViewPunch = 0

SWEP.PrimaryFireInterval = 1

function SWEP:PostInitialize()
	base_class.PostInitialize(self)

	self:SetHoldType("shotgun")
end

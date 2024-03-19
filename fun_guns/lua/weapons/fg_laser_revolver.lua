SWEP.Base = "fg_laser_pistol"

local base_class = fg_base.SetupSWEP(SWEP, "Laser Revolver")

SWEP.ViewModel = "models/weapons/c_357.mdl"

SWEP.WorldModel = "models/weapons/w_357.mdl"

SWEP.Primary.Ammo = "357"

SWEP.Primary.ClipSize = 6

SWEP.Primary.DefaultClip = 6

SWEP.Primary.Damage = 1234

SWEP.Primary.Spread = 0.075

SWEP.Primary.VerticalViewPunch = 12

SWEP.Primary.HorizontalViewPunch = 0

SWEP.PrimaryFireInterval = 0.75

function SWEP:PostInitialize()
	base_class.PostInitialize(self)

	self:SetHoldType("revolver")
end

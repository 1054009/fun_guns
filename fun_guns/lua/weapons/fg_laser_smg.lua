SWEP.Base = "fg_laser_pistol"

local base_class = fg_base.SetupSWEP(SWEP, "Laser SMG")

SWEP.ViewModel = "models/weapons/c_smg1.mdl"

SWEP.WorldModel = "models/weapons/w_smg1.mdl"

SWEP.Primary.Ammo = "SMG1"

SWEP.Primary.ClipSize = 45

SWEP.Primary.DefaultClip = 45

SWEP.Primary.Automatic = true

SWEP.Primary.Damage = 80

SWEP.Primary.Spread = 0.2

SWEP.PrimaryFireInterval = 0.1

function SWEP:PostInitialize()
	base_class.PostInitialize(self)

	self:SetHoldType("smg")
end

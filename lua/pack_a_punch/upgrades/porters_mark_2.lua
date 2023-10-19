local UPGRADE = {}
UPGRADE.id = "porters_mark_2"
UPGRADE.class = "tfa_raygun_mark2"
UPGRADE.name = "Porter's Mark II"
UPGRADE.desc = "6-round burst + extra ammo"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()
    SWEP.DefaultFireMode = "6 Burst"

    SWEP.FireModes = {"6 Burst"}

    SWEP.FireModeName = "6 Burst"
end

TTTPAP:Register(UPGRADE)
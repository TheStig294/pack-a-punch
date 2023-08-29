local UPGRADE = {}
UPGRADE.id = "eagles_eye"
UPGRADE.class = "weapon_ttt_binoculars"
UPGRADE.name = "Eagle's Eye"
UPGRADE.desc = "Faster and further zoom, instantly search bodies!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        SWEP.ZoomLevels = {0, 15, 10, 5}

        SWEP.ProcessingDelay = 0.1
    end
end

TTTPAP:Register(UPGRADE)
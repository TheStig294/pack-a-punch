local UPGRADE = {}
UPGRADE.id = "fart_cannon"
UPGRADE.class = "tfa_scavenger"
UPGRADE.name = "Fart Cannon"
UPGRADE.desc = "1.5x ammo, plays fart noises"
UPGRADE.ammoMult = 1.5

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()

    timer.Simple(0.1, function()
        self.Primary_TFA.ClipSize = 3
    end)
end

TTTPAP:Register(UPGRADE)
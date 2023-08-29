local UPGRADE = {}
UPGRADE.id = "elmo_igniter"
UPGRADE.class = "weapon_ars_igniter"
UPGRADE.name = "Elmo Igniter"
UPGRADE.desc = "Displays the burning elmo meme while held"

function UPGRADE:Apply(SWEP)
    if SERVER then return end
    SWEP.ElmoMaterial = Material("ttt_pack_a_punch/elmo_igniter/elmoburn")

    function SWEP:DrawHUDBackground()
        surface.SetAlphaMultiplier(0.1)
        surface.SetDrawColor(39, 39, 39, 39)
        surface.SetMaterial(self.ElmoMaterial)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        surface.SetAlphaMultiplier(1)
        if isfunction(self.BaseClass.DrawHUD) then return self.BaseClass.DrawHUD(self) end
    end
end

TTTPAP:Register(UPGRADE)
TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_ars_igniter = {
    name = "Buuuuuurn",
    desc = "Does nothing different other than\ndisplay the burning elmo meme...",
    firerateMult = 1,
    func = function(SWEP)
        if SERVER then return end
        SWEP.ElmoMaterial = Material("ttt_pack_a_punch/arsonist_igniter/elmoburn")

        function SWEP:DrawHUDBackground()
            surface.SetAlphaMultiplier(0.1)
            surface.SetDrawColor(39, 39, 39, 39)
            surface.SetMaterial(self.ElmoMaterial)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
            surface.SetAlphaMultiplier(1)
            if isfunction(self.BaseClass.DrawHUD) then return self.BaseClass.DrawHUD(self) end
        end
    end
}
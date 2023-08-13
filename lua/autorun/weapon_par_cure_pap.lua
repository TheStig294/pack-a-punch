TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_par_cure = {
    name = "Living Parasite Cure",
    desc = "Works on living parasite players instead!",
    func = function(SWEP)
        SWEP.SingleUse = false
        local cured = Sound("items/smallmedkit1.wav")

        function SWEP:OnSuccess(ply)
            ply:EmitSound(cured)
            local owner = self:GetOwner()

            if ply:IsParasite() then
                ply:Kill()
                owner:QueueMessage(MSG_PRINTCENTER, ply:Nick() .. " was " .. ROLE_STRINGS_EXT[ROLE_PARASITE] .. "!")
                self:Remove()
            else
                owner:QueueMessage(MSG_PRINTCENTER, ply:Nick() .. " is not " .. ROLE_STRINGS_EXT[ROLE_PARASITE] .. "...")
            end
        end
    end
}
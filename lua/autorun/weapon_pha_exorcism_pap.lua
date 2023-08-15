TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_pha_exorcism = {
    name = "Ghost Buster",
    desc = "Multiple uses, kills a phantom without them haunting you!",
    func = function(SWEP)
        SWEP.SingleUse = false
        local cured = Sound("items/smallmedkit1.wav")
        local oldOnSuccess = SWEP.OnSuccess

        function SWEP:OnSuccess(ply)
            ply:EmitSound(cured)
            local owner = self:GetOwner()

            if ply:IsPhantom() then
                ply:Kill()
                owner:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " was " .. ROLE_STRINGS_EXT[ROLE_PHANTOM] .. "!")
            else
                owner:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " is not " .. ROLE_STRINGS_EXT[ROLE_PHANTOM] .. ", but any phantom haunting was cleared!")
                oldOnSuccess(self, ply)
            end
        end
    end
}
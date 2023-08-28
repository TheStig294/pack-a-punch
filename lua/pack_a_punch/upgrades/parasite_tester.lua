local UPGRADE = {}
UPGRADE.id = "parasite_tester"
UPGRADE.class = "weapon_par_cure"
UPGRADE.name = "Parasite Tester"
UPGRADE.desc = "Works on living parasite players instead!"

function UPGRADE:Apply(SWEP)
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

TTTPAP:Register(UPGRADE)
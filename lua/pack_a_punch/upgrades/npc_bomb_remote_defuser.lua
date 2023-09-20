local UPGRADE = {}
UPGRADE.id = "npc_bomb_remote_defuser"
UPGRADE.class = "weapon_ttt_rsb_defuser"
UPGRADE.name = "NPC Bomb Defuser"
UPGRADE.desc = "Removes the NPC bomb you're looking at"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not UPGRADE:IsPlayer(owner) then return end
        local tgt = owner:GetEyeTrace().Entity
        if not IsValid(tgt) then return end

        if tgt.PAPNpcBomb then
            tgt:Kick()
            owner:PrintMessage(HUD_PRINTTALK, "Bomb has been defused!")
            -- Sound is from CSS, doesn't really matter if people don't have it installed and don't hear it
            owner:EmitSound("radio/bombdef.wav")
            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)
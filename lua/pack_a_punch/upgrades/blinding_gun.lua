local UPGRADE = {}
UPGRADE.id = "blinding_gun"
UPGRADE.class = "weapon_ttt_dd"
UPGRADE.name = "All Blinding Gun"
UPGRADE.desc = "Affects everyone! (except you)"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()

        if SERVER and IsValid(owner) and self:CanPrimaryAttack() then
            for _, ply in player.Iterator() do
                if ply ~= owner then
                    DareDevil(ply, owner, SWEP)
                end
            end
        end

        return self:PAPOldPrimaryAttack()
    end
end

TTTPAP:Register(UPGRADE)
local UPGRADE = {}
UPGRADE.id = "prop_transformer"
UPGRADE.class = "weapon_ttt_prop_hunt_gun"
UPGRADE.name = "Prop Transformer"
UPGRADE.desc = "Permanently transforms someone else into a prop!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        local TraceResult = owner:GetEyeTrace()
        local victim = TraceResult.Entity

        if UPGRADE:IsPlayer(victim) then
            -- Random number nonsense to bypass weapon slots
            victim:Give(UPGRADE.class).Kind = 9206
            local disguiser = victim:GetWeapon(UPGRADE.class)
            disguiser:PrimaryAttack()

            if IsFirstTimePredicted() then
                timer.Simple(5, function()
                    if IsValid(victim) then
                        victim:ChatPrint("Someone turned you into a prop using the upgraded prop disguiser!")
                    end
                end)

                function disguiser:PrimaryAttack()
                    if CLIENT then return end
                    local own = self:GetOwner()

                    if IsValid(own) then
                        victim:PrintMessage(HUD_PRINTCENTER, "You're stuck as a prop, go hide!")
                    end
                end

                self:Remove()
                owner:ConCommand("lastinv")
            end
        end
    end
end

TTTPAP:Register(UPGRADE)
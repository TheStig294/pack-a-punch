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
            local timername = victim:SteamID64() .. "TTTPAPPropTransformerTaunts"

            local soundNumbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

            table.Shuffle(soundNumbers)
            local soundIndex = 1

            -- Create timer to force extra taunts
            timer.Create(timername, 20, 0, function()
                if IsValid(victim) and IsValid(victim.ttt_prop) and victim:GetNWBool("PD_Disguised") then
                    local randomSound = "ttt_pack_a_punch/shouting_credit_printer/quote" .. soundNumbers[soundIndex] .. ".mp3"
                    owner:EmitSound(randomSound)
                    owner:EmitSound(randomSound)
                    soundIndex = soundIndex + 1

                    if soundIndex > 11 then
                        soundIndex = 1
                        table.Shuffle(soundNumbers)
                    end
                else
                    timer.Remove(timername)
                end
            end)

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
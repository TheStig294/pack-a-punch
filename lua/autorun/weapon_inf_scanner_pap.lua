TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

local timeCvar = CreateConVar("ttt_pap_inf_scanner_time", "30", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds players can be seen", 1, 60)

local class = "weapon_inf_scanner_pap"
TTT_PAP_CONVARS[class] = {}

table.insert(TTT_PAP_CONVARS[class], {
    name = "ttt_pap_inf_scanner_time",
    type = "int"
})

TTT_PAP_UPGRADES.weapon_inf_scanner = {
    name = "Scanner Pinger",
    desc = "Left-Click to see everyone through walls\nfor " .. timeCvar:GetInt() .. " seconds, but this removes your scanner!",
    func = function(SWEP)
        local outlinedPlayers = {}
        local beepSound = Sound("tools/ifm/beep.wav")

        function SWEP:PrimaryAttack()
            if SERVER then
                if Randomat and Randomat.IsEventActive and Randomat:IsEventActive("prophunt") then
                    self:GetOwner():PrintMessage(HUD_PRINTCENTER, "You cannot use this function during 'Prop Hunt'!")

                    return
                else
                    self:GetOwner():ViewPunch(Angle(0, 0, 0))
                    self:Remove()
                end
            end

            if CLIENT then
                -- Wait a second to see if weapon was removed or not,
                -- if it wasn't, Prop Hunt is probably active
                timer.Simple(0.1, function()
                    if IsValid(self) then return end
                    surface.PlaySound(beepSound)

                    for _, ply in pairs(player.GetAll()) do
                        if ply:Alive() and not ply:IsSpec() then
                            table.insert(outlinedPlayers, ply)
                        end
                    end

                    timer.Simple(timeCvar:GetInt(), function()
                        table.Empty(outlinedPlayers)
                    end)

                    hook.Add("PreDrawHalos", "TTTPAPUsedInformantScanner", function()
                        for i, ply in ipairs(outlinedPlayers) do
                            if IsValid(ply) and (not ply:Alive() or ply:IsSpec()) then
                                outlinedPlayers[i] = false
                            end
                        end

                        halo.Add(outlinedPlayers, Color(255, 255, 255), 0, 0, 1, true, true)
                    end)

                    hook.Add("TTTPrepareRound", "TTTPAPResetInformantScanner", function()
                        table.Empty(outlinedPlayers)
                        hook.Remove("PreDrawHalos", "TTTPAPUsedInformantScanner")
                        hook.Remove("TTTPrepareRound", "TTTPAPResetInformantScanner")
                    end)
                end)
            end
        end
    end
}
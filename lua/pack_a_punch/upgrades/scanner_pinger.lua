local UPGRADE = {}
UPGRADE.id = "scanner_pinger"
UPGRADE.class = "weapon_inf_scanner"
UPGRADE.name = "Scanner Pinger",

local timeCvar = CreateConVar("ttt_pap_inf_scanner_time", "30", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds players can be seen", 1, 60)

UPGRADE.desc = "Left-Click to see everyone through walls for " .. timeCvar:GetInt() .. " seconds,\nbut this removes your scanner!",

UPGRADE.convars = {
    {
        name = "ttt_pap_inf_scanner_time",
        type = "int"
    }
}

local outlinedPlayers = {}

function UPGRADE:Apply(SWEP)
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
                table.Empty(outlinedPlayers)

                for _, ply in pairs(player.GetAll()) do
                    if ply:Alive() and not ply:IsSpec() then
                        table.insert(outlinedPlayers, ply)
                    end
                end

                timer.Simple(timeCvar:GetInt(), function()
                    table.Empty(outlinedPlayers)
                end)
            end)
        end
    end

    if CLIENT then
        self:AddHook("PreDrawHalos", "TTTPAPUsedInformantScanner", function()
            for i, ply in ipairs(outlinedPlayers) do
                if IsValid(ply) and (not ply:Alive() or ply:IsSpec()) then
                    outlinedPlayers[i] = false
                end
            end

            halo.Add(outlinedPlayers, Color(255, 255, 255), 0, 0, 1, true, true)
        end)
    end
end

function UPGRADE:Reset()
    table.Empty(outlinedPlayers)
end

TTTPAP:Register(UPGRADE)
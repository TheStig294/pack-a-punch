local UPGRADE = {}
UPGRADE.id = "hack_the_planet"
UPGRADE.class = "c_sombra_gun_n"
UPGRADE.name = "Hack the planet!"
UPGRADE.desc = "On right-click,\nTemporarily disables everyone's healing and currently held weapon"

UPGRADE.convars = {
    {
        name = "pap_hack_the_planet_duration",
        type = "int"
    }
}

local durationCvar = CreateConVar("pap_hack_the_planet_duration", "120", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds duration of hack effect", 1, 300)

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPHackThePlanetPopup")
    end

    local client
    local popupAlpha
    local showPopup = false

    local function DoClientHackedPopup()
        client = LocalPlayer()
        popupAlpha = 0
        showPopup = true

        timer.Create("TTTPAPHackThePlanetPopup", 0.01, 120, function()
            local repsLeft = timer.RepsLeft("TTTPAPHackThePlanetPopup")

            if repsLeft >= 100 then
                popupAlpha = popupAlpha + 0.05
            elseif repsLeft < 20 then
                popupAlpha = popupAlpha - 0.05
            end

            if repsLeft == 0 then
                showPopup = false
            end
        end)
    end

    local function HackedPopup(ply)
        if not IsValid(ply) or showPopup then return end

        if SERVER then
            ply:EmitSound("Weapon_Pistol.Empty")
            net.Start("TTTPAPHackThePlanetPopup")
            net.Send(ply)
        else
            ply:EmitSound("Weapon_Pistol.Empty")
            DoClientHackedPopup()
        end
    end

    if CLIENT then
        net.Receive("TTTPAPHackThePlanetPopup", DoClientHackedPopup)
        local hackedMat = Material("ttt_pack_a_punch/hack_the_planet/hacked.png")

        self:AddHook("PostDrawHUD", function()
            if not client or not showPopup then return end
            surface.SetMaterial(hackedMat)
            surface.SetDrawColor(255, 255, 255, popupAlpha * 255)
            surface.DrawTexturedRect(ScrW() / 2 - 128, ScrH() / 2 - 128, 256, 256)
        end)
    end

    self:AddToHook(SWEP, "SecondaryAttack", function()
        if SWEP.TTTPAPHackThePlanetUsed then return end
        SWEP.TTTPAPHackThePlanetUsed = true
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end

        if SERVER then
            owner:EmitSound("ttt_pack_a_punch/hack_the_planet/activate.mp3", 0)

            timer.Simple(0.5, function()
                owner:EmitSound("ambient/levels/labs/electric_explosion1.wav", 0)
                util.ScreenShake(owner:GetPos(), 6, 40, 2, 1000, true)
            end)
        end

        if CLIENT and owner:HasWeapon("weapon_ttt_unarmed") then
            input.SelectWeapon(owner:GetWeapon("weapon_ttt_unarmed"))

            timer.Simple(0.5, function()
                if IsValid(SWEP) then
                    input.SelectWeapon(SWEP)
                end
            end)
        end

        timer.Simple(0.5, function()
            for _, ply in player.Iterator() do
                HackedPopup(ply)
                -- Display the "hacked" popup for the owner, but don't actually hack their weapon!
                if IsValid(owner) and IsValid(SWEP) and ply == owner then continue end

                if SERVER then
                    ply:ChatPrint("Your weapon and healing have been hacked!")
                    ply.TTTPAPHackThePlanetHealth = ply:Health()
                    local wep = ply:GetActiveWeapon()

                    if IsValid(wep) then
                        wep:SetNWBool("TTTHackThePlanet", true)
                    end

                    ply:SelectWeapon("weapon_ttt_unarmed")
                end
            end
        end)

        -- Purposfully give this timer a non-unique name so it gets reset whenever another player uses this upgrade while one is already in effect
        timer.Create("TTTPAPHackThePlanet", durationCvar:GetInt(), 1, function()
            for _, ply in player.Iterator() do
                ply.TTTPAPHackThePlanetHealth = nil
                ply:PrintMessage(HUD_PRINTCENTER, "Your weapon and healing are no longer hacked!")
            end

            for _, ent in ents.Iterator() do
                if IsValid(ent) and ent:IsWeapon() then
                    ent:SetNWBool("TTTHackThePlanet", nil)
                end
            end
        end)
    end)

    self:AddHook("PlayerPostThink", function(ply)
        if not ply.TTTPAPHackThePlanetHealth then return end

        if ply.TTTPAPHackThePlanetHealth < ply:Health() then
            ply:SetHealth(ply.TTTPAPHackThePlanetHealth)
        else
            ply.TTTPAPHackThePlanetHealth = ply:Health()
        end
    end)

    local attackKeys = {IN_ATTACK, IN_ATTACK2, IN_RELOAD}

    self:AddHook("StartCommand", function(ply, cmd)
        local wep = ply:GetActiveWeapon()

        if IsValid(wep) and wep:GetNWBool("TTTHackThePlanet", false) then
            local attackKeyDown = false

            for _, key in ipairs(attackKeys) do
                if cmd:KeyDown(key) then
                    cmd:RemoveKey(key)
                    attackKeyDown = true
                end
            end

            if attackKeyDown then
                HackedPopup(ply)
            end
        end
    end)
end

function UPGRADE:Reset()
    timer.Remove("TTTPAPHackThePlanet")

    for _, ply in player.Iterator() do
        ply.TTTPAPHackThePlanetHealth = nil
    end
end

TTTPAP:Register(UPGRADE)
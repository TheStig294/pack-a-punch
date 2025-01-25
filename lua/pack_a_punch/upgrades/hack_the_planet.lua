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
    local client
    local popupAlpha

    -- TODO: Send this function to clients so everyone other than the owner actually sees it!
    local function HackedPopup(ply)
        if not IsValid(ply) or ply.TTTPAPHackThePlanetPopup then return end
        ply:EmitSound("Weapon_Pistol.Empty")

        if CLIENT then
            client = LocalPlayer()
            popupAlpha = 0
            ply.TTTPAPHackThePlanetPopup = true

            timer.Create("TTTPAPHackThePlanetPopup", 0.01, 120, function()
                local repsLeft = timer.RepsLeft("TTTPAPHackThePlanetPopup")

                if repsLeft >= 100 then
                    popupAlpha = popupAlpha + 0.05
                elseif repsLeft < 20 then
                    popupAlpha = popupAlpha - 0.05
                end

                if repsLeft == 0 then
                    ply.TTTPAPHackThePlanetPopup = false
                end
            end)
        end
    end

    if CLIENT then
        local hackedMat = Material("ttt_pack_a_punch/hack_the_planet/hacked.png")

        self:AddHook("PostDrawHUD", function()
            if not client or not client.TTTPAPHackThePlanetPopup then return end
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
        owner:EmitSound("ttt_pack_a_punch/hack_the_planet/activate.mp3", 0)

        timer.Simple(0.5, function()
            owner:EmitSound("ambient/levels/labs/electric_explosion1.wav", 0)
            util.ScreenShake(owner:GetPos(), 6, 40, 2, 1000, true)
        end)

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
                    ply:ChatPrint("Your current weapon and healing have been disabled!")
                end

                ply.TTTPAPHackThePlanetHealth = ply:Health()
                ply.TTTPAPHackThePlanetWeapon = ply:GetActiveWeapon()
            end
        end)

        -- Purposfully give this timer a non-unique name so it gets reset whenever another player uses this upgrade while one is already in effect
        local timername = "TTTPAPHackThePlanet"

        timer.Create(timername, durationCvar:GetInt(), 1, function()
            for _, ply in player.Iterator() do
                ply.TTTPAPHackThePlanetHealth = nil
                ply.TTTPAPHackThePlanetWeapon = nil
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
        if not IsValid(ply.TTTPAPHackThePlanetWeapon) then return end
        local wep = ply:GetActiveWeapon()

        if IsValid(wep) and wep == ply.TTTPAPHackThePlanetWeapon then
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
-- TTTPAP:Register(UPGRADE)
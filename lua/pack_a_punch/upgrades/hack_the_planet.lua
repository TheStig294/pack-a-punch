local UPGRADE = {}
UPGRADE.id = "hack_the_planet"
UPGRADE.class = "template"
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

    local function HackFunction(wep)
        local owner = wep:GetOwner()
        if not IsValid(owner) then return end

        if CLIENT then
            client = LocalPlayer()
            popupAlpha = 0

            timer.Create("TTTPAPHackThePlanetPopup", 0.01, 500, function()
                local repsLeft = timer.RepsLeft("TTTPAPHackThePlanetPopup")

                if repsLeft >= 400 then
                    popupAlpha = popupAlpha + 0.01
                elseif repsLeft < 100 then
                    popupAlpha = popupAlpha - 0.01
                end
            end)

            owner.TTTPAPHackThePlanetPopup = true

            timer.Simple(5, function()
                owner.TTTPAPHackThePlanetPopup = false
            end)
        end
    end

    if CLIENT then
        local hackedMat = Material("ttt_pack_a_punch/hack_the_planet/hacked.png")

        self:AddHook("PostDrawHUD", function()
            if not client or not client.TTTPAPHackThePlanetPopup then return end
            surface.SetMaterial(hackedMat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetAlphaMultiplier(popupAlpha)
            surface.DrawTexturedRect(ScrW() / 2, ScrH() / 2, 256, 256)
            surface.SetAlphaMultiplier(1)
        end)
    end

    local function HackWeapon(wep)
        if not IsValid(wep) then return end

        for _, hookName in ipairs({"PrimaryAttack", "SecondaryAttack", "Reload"}) do
            wep["TTTPAPHackThePlanet" .. hookName] = wep[hookName]
            wep[hookName] = HackFunction
        end
    end

    local function UnHackWeapon(wep)
        if not IsValid(wep) then return end

        for _, hookName in ipairs({"PrimaryAttack", "SecondaryAttack", "Reload"}) do
            wep[hookName] = wep["TTTPAPHackThePlanet" .. hookName]
            wep["TTTPAPHackThePlanet" .. hookName] = nil
        end
    end

    self:AddToHook(SWEP, "SecondaryAttack", function()
        if SWEP.TTTPAPHackThePlanetUsed then return end
        SWEP.TTTPAPHackThePlanetUsed = true
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        owner:EmitSound("ttt_pack_a_punch/hack_the_planet/activate.mp3", 0)

        for _, ply in player.Iterator() do
            if ply == owner then continue end
            ply.TTTPAPHackThePlanetHealth = ply:Health()
            ply.TTTPAPHackThePlanetWeapon = ply:GetActiveWeapon()
            HackFunction(ply.TTTPAPHackThePlanetWeapon)
            HackWeapon(ply.TTTPAPHackThePlanetWeapon)
        end

        -- Purposfully give this timer a non-unique name so it gets reset whenever another player uses this upgrade while one is already in effect
        local timername = "TTTPAPHackThePlanet"

        timer.Create(timername, durationCvar:GetInt(), 1, function()
            for _, ply in player.Iterator() do
                ply.TTTPAPHackThePlanetHealth = nil
                UnHackWeapon(ply.TTTPAPHackThePlanetWeapon)
                ply.TTTPAPHackThePlanetWeapon = nil
            end
        end)
    end)

    self:AddHook("PlayerPostThink", function(ply)
        if not ply.TTTPAPHackThePlanetHealth then return end

        if ply.TTTPAPHackThePlanetHealth > ply:Health() then
            ply:SetHealth(ply.TTTPAPHackThePlanetHealth)
        else
            ply.TTTPAPHackThePlanetHealth = ply:Health()
        end
    end)
end
-- TTTPAP:Register(UPGRADE)
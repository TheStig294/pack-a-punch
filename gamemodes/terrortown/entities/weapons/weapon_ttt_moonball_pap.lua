if engine.ActiveGamemode() ~= "terrortown" then return end

-- Modifying the basketball weapon to use TTTBase
hook.Add("InitPostEntity", "TTTPAPMoonballModifyBase", function()
    local basketballSWEP = weapons.GetStored("weapon_ballin")

    if basketballSWEP then
        basketballSWEP.Base = "weapon_tttbase"
    end
end)

SWEP.Base = "weapon_ballin"

-- Check if the moonball is a floor weapon or not
if ConVarExists("ttt_joke_weapons_moonball_spawn_on_floor") and not GetConVar("ttt_joke_weapons_moonball_spawn_on_floor"):GetBool() then
    SWEP.Kind = WEAPON_NADE
    SWEP.Slot = 3
else
    SWEP.Kind = 317
    SWEP.Slot = 9
end

SWEP.PrintName = "Basketball"
SWEP.InLoadoutFor = nil
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.ViewModelFlip = true
SWEP.DrawAmmo = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.ClipMax = -1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.ClipMax = -1
SWEP.Icon = "vgui/entities/weapon_ballin"
SWEP.WorldModel = "models/basketball.mdl"
-- Add a hook to give the basketball weapon to a player if they interact with the thrown ball entity
local hookAdded = false

function SWEP:Initialize()
    if SERVER and not hookAdded then
        hook.Add("PlayerUse", "PAPMoonballUseBasketball", function(ply, ent)
            if not IsValid(ent) then return end
            local model = ent:GetModel()

            if model and model == "models/basketball.mdl" and ent:GetClass() == "prop_physics" then
                ply:Give("weapon_ttt_moonball_pap")
                ent:Remove()
            end
        end)
    end

    self:SetClip1(0)
end

if SERVER then
    function SWEP:ThrowBall(model_file, throwDown)
        self.BaseClass.ThrowBall(self, model_file, throwDown)
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:EmitSound("ttt_moonball_pap/slam.mp3")
        end

        self:Remove()
    end
end
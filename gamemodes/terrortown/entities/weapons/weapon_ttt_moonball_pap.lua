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
    SWEP.Kind = 317
    SWEP.Slot = 9
else
    SWEP.Kind = WEAPON_NADE
    SWEP.Slot = 3
end

local SWEPKind = SWEP.Kind
SWEP.PrintName = "Basketball"
SWEP.InLoadoutFor = nil
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.ViewModelFlip = true
SWEP.DrawAmmo = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.ClipMax = 1
SWEP.Secondary.Ammo = "none"
SWEP.Icon = "vgui/entities/weapon_ballin"
SWEP.WorldModel = "models/basketball.mdl"
SWEP.PAPNoCamo = true
SWEP.PAPDesc = "A basketball that can be picked up again!\nDisappears if not picked up after a while"
-- Add a hook to give the basketball weapon to a player if they interact with the thrown ball entity
local hookAdded = false

function SWEP:Initialize()
    if SERVER and not hookAdded then
        hook.Add("PlayerUse", "PAPMoonballUseBasketball", function(ply, ent)
            if not IsValid(ent) then return end
            local model = ent:GetModel()

            if model and model == "models/basketball.mdl" and ent:GetClass() == "prop_physics" then
                -- Remove weapons of the same kind when trying to pick up the basketball
                for _, wep in ipairs(ply:GetWeapons()) do
                    if wep.Kind == SWEPKind then
                        ply:StripWeapon(wep:GetClass())
                    end
                end

                ply:Give("weapon_ttt_moonball_pap")

                timer.Simple(0.1, function()
                    ply:SelectWeapon("weapon_ttt_moonball_pap")
                end)

                ent:Remove()
            end
        end)
    end

    timer.Simple(0.1, function()
        self:SetClip1(1)
    end)
end

function SWEP:Equip()
    self.ViewModelFlip = true
    self.DrawAmmo = false
    self:SetNWBool("IsPackAPunched", true)
    self.BaseClass.Equip(self)
end

function SWEP:OnRemove()
    self:Holster()
    self.releaseCheck = false
    self.releaseCheck2 = false
end

function SWEP:ThrowBall(model_file, throwDown)
    self.BaseClass.ThrowBall(self, model_file, throwDown)
    self.releaseCheck = false
    self.releaseCheck2 = false

    if SERVER then
        local owner = self:GetOwner()

        if throwDown and IsValid(owner) then
            owner:EmitSound("ttt_moonball_pap/slam.mp3")
        end

        self:Remove()
    end
end
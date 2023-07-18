AddCSLuaFile()
SWEP.Base = "doncmk2_swep"
SWEP.PrintName = "Big Boi Donconnon"
SWEP.PAPDesc = "Bigger hitbox, bigger explosion, leaves fire"

function SWEP:PrimaryAttack()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local doncon = ents.Create("doncmk2_en_pap") -- Spawn PAP ent
    if not IsValid(doncon) then return end
    doncon:SetPos(owner:EyePos() + owner:GetAimVector() * 200)
    doncon:SetAngles(owner:EyeAngles())
    doncon:SetOwner(owner)
    doncon.SWEP = self

    if self.LockOnTarget ~= "none" then
        doncon.Homing = true
        doncon.Target = self.LockOnTarget
    else
        doncon.Homing = false
    end

    doncon.DonconDamage = 60
    doncon.DonconSpeed = 200
    doncon.DonconRange = 2000
    doncon.DonconScale = 1.5 -- x2 default size
    doncon.DonconTurn = 0.00025
    doncon.Sound = "ttt_pack_a_punch/donconnon/o_rubber_tree_big.mp3" -- New sound
    doncon:Spawn()
    self:UpdateHalo("none")
    self:Remove()
end
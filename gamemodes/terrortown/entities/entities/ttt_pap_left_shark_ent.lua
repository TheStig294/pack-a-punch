AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_shark_ent"
ENT.PrintName = "Left Shark Ent"
local leftSharkModel = "models/freeman/player/left_shark.mdl"
local sharkyModel = "models/bradyjharty/yogscast/sharky.mdl"

-- Pick a shark model at random if both installed
function ENT:Initialize()
    local model = "models/thebonbon/ttt_shark_ent.mdl"

    if util.IsValidModel(leftSharkModel) and math.random() < 0.5 then
        model = leftSharkModel
    elseif util.IsValidModel(sharkyModel) then
        model = sharkyModel
    end

    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(SOLID_VPHYSICS)
end
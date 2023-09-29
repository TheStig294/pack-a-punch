local UPGRADE = {}
UPGRADE.id = "chonk_pigeon"
UPGRADE.class = "swep_homingpigeon"
UPGRADE.name = "Chonk Pigeon"
UPGRADE.desc = "Bigger model, larger explosion, leaves fire"

function UPGRADE:Apply(SWEP)
    local own = SWEP:GetOwner()
    own.PAPChonkPigeon = true

    local BirdSounds = {"ambient/creatures/seagull_idle1.wav", "ambient/creatures/seagull_idle2.wav", "ambient/creatures/seagull_idle3.wav", "ambient/creatures/seagull_pain1.wav", "ambient/creatures/seagull_pain2.wav", "ambient/creatures/seagull_pain3.wav"}

    self:AddHook("OnEntityCreated", function(ent)
        if IsValid(ent) and ent:GetClass() == "sent_homingpigeon" then
            timer.Simple(0, function()
                local owner = ent:GetOwner()

                if owner.PAPChonkPigeon then
                    owner.PAPChonkPigeon = false
                    ent:SetMaterial(TTTPAP.camo)
                    ent:SetModelScale(3, 0.001)
                    ent:Activate()

                    for _, snd in ipairs(BirdSounds) do
                        ent:StopSound(snd)
                    end

                    local snd = BirdSounds[math.random(1, #BirdSounds)]
                    ent:EmitSound(snd, 0, 25, 1, CHAN_AUTO, SND_CHANGE_PITCH)

                    function ent:Explode()
                        if not self.Exploded then
                            self:EmitSound("ambient/explosions/explode_3.wav")
                            self.Explosion:Explode(self, self:GetPos(), GetConVar("ttt_hompigeon_damage"):GetInt() * 1.5, GetConVar("ttt_hompigeon_radius"):GetInt() * 1.5, self:GetOwner(), ents.Create("swep_homingpigeon"), "Explosion", false)
                            self.Exploded = true
                            -- Leaves a bunch of fire on exploding
                            local tr = util.QuickTrace(self:GetPos(), Vector(0, 0, -1))
                            StartFires(self:GetPos(), tr, 20, 40, false, self:GetOwner())
                        end
                    end
                end
            end)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPChonkPigeon = nil
    end
end

TTTPAP:Register(UPGRADE)
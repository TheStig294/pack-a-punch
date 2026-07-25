local UPGRADE = {}
UPGRADE.id = "boost_pad"
UPGRADE.class = "weapon_ttt_glue_trap"
UPGRADE.name = "Boost Pad"
UPGRADE.desc = "Launches players away, harder to see!"

function UPGRADE:Apply(SWEP)
    local funnyFlingSounds = {"ttt_pack_a_punch/flinging_spin_attack/fling.mp3", "ttt_pack_a_punch/the_yeet_disk/yeet.mp3", "ttt_pack_a_punch/dramatic_death_note/cartoon_fling_sound.mp3"}

    local soundCount = #funnyFlingSounds

    function SWEP:CreateHammer(_, pos, normal)
        local glue = ents.Create("glue_trap_paste")

        if IsValid(glue) then
            local ang = normal:Angle()
            ang:RotateAroundAxis(ang:Right(), 90)
            glue:SetPos(pos)
            glue:SetAngles(ang)
            glue:Spawn()
            UPGRADE:SetUpgraded(glue)
            glue:SetRenderMode(RENDERMODE_TRANSCOLOR)
            glue:SetColor(Color(255, 255, 255, 50))
            glue.TTTPAPBoostPadSoundIndex = 1
            glue.TTTPAPBoostPadSounds = funnyFlingSounds
            table.Shuffle(glue.TTTPAPBoostPadSounds)

            function glue:Touch(ply)
                if ply:IsPlayer() and ply:GetMoveType() == MOVETYPE_WALK then
                    local norm = ply:GetForward()
                    local boostVector = norm * 1000 + Vector(0, 0, 1000)
                    ply:SetGroundEntity(NULL)
                    ply:SetVelocity(boostVector)

                    if self.TTTPAPBoostPadSoundIndex > soundCount then
                        self.TTTPAPBoostPadSoundIndex = 1
                        table.Shuffle(glue.TTTPAPBoostPadSounds)
                    end

                    self:EmitSound(self.TTTPAPBoostPadSounds[self.TTTPAPBoostPadSoundIndex])
                    self.TTTPAPBoostPadSoundIndex = self.TTTPAPBoostPadSoundIndex + 1
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)
local UPGRADE = {}
UPGRADE.id = "bee_movie_script_bookquill"
UPGRADE.class = "weapon_ttt_bookquill"
UPGRADE.name = "Bee Movie Script"
UPGRADE.desc = "According to all known laws of aviation..."

function UPGRADE:Apply(SWEP)
    table.insert(SWEP.BookTexts, 1, {
        Text = [[According to all known laws of aviation, there is no way a bee should be able to fly.
Its wings are too small to get its fat little body off the ground.
The bee, of course, flies anyway because bees don't care what humans think is impossible.]]
    })

    if CLIENT then
        self:AddToHook(SWEP, "OpenBook", function()
            if SWEP.TTTPAPBeeMovieScriptPlayed then return end
            surface.PlaySound("ttt_pack_a_punch/bee_movie_script/bee_movie_script.mp3")
            SWEP.TTTPAPBeeMovieScriptPlayed = true
        end)
    end
end

TTTPAP:Register(UPGRADE)
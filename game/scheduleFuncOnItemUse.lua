require "game.scheduleFuncTowerSkillBook"

-- 使用物品
onUnitItemsUesd = function(evtData)
    local u = evtData.triggerUnit
    local it = evtData.triggerItem
    local itId = hitem.getId(it)
    local itemSLK = hslk_global.itemsKV[itId]
    local p = cj.GetOwningPlayer(u)
    if (itemSLK == nil or itemSLK.INDEX == nil) then
        hmsg.echo00(p, "slk获取错误")
        return
    end
    if (itemSLK.I_TYPE == nil) then
        hmsg.echo00(p, "物品I类型获取错误")
        return
    end
    if (itemSLK.I_TYPE == "tower") then
        --tower
        local playerIndex = hplayer.index(p)
        local marks = {
            hunit.getSlk(game.playerTower[playerIndex]).MARK or 0
        }
        local names = {
            "[主兵]" .. hunit.getName(game.playerTower[playerIndex])
        }
        local dots = {
            string.findCount(names[1], "·")
        }
        local nls = {
            string.mb_len(names[1]) - dots[1]
        }
        local bigMark = marks[1]
        local bigNameLen = string.mb_len(names[1])
        local bigDotLen = dots[1]
        for i = 1, 4, 1 do
            marks[i + 1] = game.playerTowerLink[playerIndex][i].mark or 0
            if (marks[i + 1] > bigMark) then
                bigMark = marks[i + 1]
            end
            names[i + 1] = hunit.getName(game.playerTowerLink[playerIndex][i].unit)
            if (names[i + 1] == "空位") then
                names[i + 1] = "[N阶]空位"
            end
            names[i + 1] = "[辅兵]" .. names[i + 1]
            dots[i + 1] = string.findCount(names[i + 1], "·")
            nls[i + 1] = string.mb_len(names[i + 1]) - dots[i + 1]
            if (nls[i + 1] > bigNameLen) then
                bigNameLen = nls[i + 1]
            end
            if (dots[i + 1] > bigDotLen) then
                bigDotLen = dots[i + 1]
            end
        end
        local bigMarkLen = string.len(tostring(bigMark))
        for i, v in ipairs(marks) do
            local vlen = string.len(tostring(v))
            if (vlen < bigMarkLen) then
                marks[i] = string.rep(" ", bigMarkLen - vlen) .. v
            end
        end
        for i, v in ipairs(names) do
            if (nls[i] < bigNameLen) then
                names[i] = v .. string.rep("　", bigNameLen - nls[i])
            end
            if (bigDotLen > dots[i]) then
                names[i] = names[i] .. string.rep(" ", bigDotLen - dots[i])
            end
        end

        local btns = {
            {
                value = 512,
                label = "[ESC][" .. hColor.grey("吞噬升1级") .. "]"
            },
            {
                value = 0,
                label = hColor.yellow(marks[1] .. "分" .. "-" .. names[1])
            }
        }
        for i = 1, 4, 1 do
            table.insert(
                btns,
                {
                    value = i,
                    label = hColor.sky(marks[i + 1] .. "分" .. "-" .. names[i + 1])
                }
            )
        end
        local title =
            "兵塔石：" ..
            game.towers[itemSLK.INDEX].MARK ..
                "分" .. game.towers[itemSLK.INDEX].TOWER_POWER .. "阶" .. game.towers[itemSLK.INDEX].Name
        hdialog.create(
            p,
            {
                title = title,
                buttons = btns
            },
            function(btnIdx)
                if (btnIdx == 512) then
                    hhero.setCurLevel(
                        game.playerTower[playerIndex],
                        1 + hhero.getCurLevel(game.playerTower[playerIndex]),
                        false
                    )
                    hmsg.echo00(p, "通过吞噬兵塔石,兵塔提升了" .. hColor.yellow(1) .. "级")
                    return
                elseif (btnIdx == 0) then
                    local u = createMyTower(playerIndex, game.towers[itemSLK.INDEX].UNIT_ID)
                    hmsg.echo(
                        hColor.sky(cj.GetPlayerName(p)) ..
                            "召唤了兵塔：[" .. hColor.yellow(game.towers[itemSLK.INDEX].Name) .. "]"
                    )
                    addTowerSkillsRaceTeam(playerIndex)
                else
                    local u = createMyTowerLink(playerIndex, btnIdx, game.towers[itemSLK.INDEX].UNIT_ID)
                    hmsg.echo(
                        hColor.sky(cj.GetPlayerName(p)) ..
                            "设置了核心：[" .. hColor.yellow(game.towers[itemSLK.INDEX].Name) .. "]"
                    )
                    addTowerSkillsRaceTeam(playerIndex)
                end
            end
        )
    elseif (itemSLK.I_TYPE == "courier") then
        --信使
        local playerIndex = hplayer.index(p)
        local u = createMyCourier(playerIndex, game.courier[itemSLK.INDEX].UNIT_ID)
        hmsg.echo(
            hColor.sky(cj.GetPlayerName(p)) .. "召唤了信使：[" .. hColor.yellow(game.courier[itemSLK.INDEX].Name) .. "]"
        )
        if (u ~= nil and cj.GetLocalPlayer() == p) then
            cj.ClearSelection()
            cj.SelectUnit(u, true)
        end
    elseif (itemSLK.I_TYPE == "ability") then
        local abils = game.thisOptionAbility[itemSLK.INDEX]
        if (abils == nil or table.len(abils) <= 0) then
            hmsg.echo00(p, "技能获取错误")
            return
        end
        local sites = {}
        if (itemSLK.ABILITY_COLOR == "yellow") then
            sites = {"S", "D"}
        elseif (itemSLK.ABILITY_COLOR == "blue") then
            sites = {"X", "C", "V"}
        elseif (itemSLK.ABILITY_COLOR == "purple") then
            sites = {"F"}
        end
        local playerIndex = hplayer.index(p)
        local btns = {}
        local emptySite = nil
        for k, v in ipairs(sites) do
            if (game.towersAbilities[playerIndex][v].ABILITY_LEVEL == nil) then
                if (emptySite == nil) then
                    emptySite = v
                    break
                end
                btns[k] = {
                    value = v,
                    label = hColor.yellow(
                        "[" .. v .. "]-[" .. hColor.grey(game.towersAbilities[playerIndex][v].Name) .. "]"
                    )
                }
            else
                btns[k] = {
                    value = v,
                    label = hColor.yellow(
                        "[" ..
                            v ..
                                "]-[" ..
                                    game.towersAbilities[playerIndex][v].Name ..
                                        "][" .. game.towersAbilities[playerIndex][v].ABILITY_LEVEL .. "级]"
                    )
                }
            end
        end
        if (emptySite == nil) then
            table.insert(
                btns,
                {
                    value = 512,
                    label = "[ESC][" .. hColor.grey("卖掉技能书") .. "]"
                }
            )
            hdialog.create(
                p,
                {
                    title = itemSLK.DIALOG_TITLE,
                    buttons = btns
                },
                function(btnIdx)
                    if (btnIdx == 512) then
                        hplayer.addGold(hplayer.players[playerIndex], 30, u)
                        return
                    end
                    hmsg.echo00(
                        p,
                        "你选择了[" ..
                            hColor.yellow(btnIdx) ..
                                "]位置，来学习[" ..
                                    hColor.yellow(abils[btnIdx].ABILITY_LEVEL .. "级" .. abils[btnIdx].Name) .. "]"
                    )
                    delTowerSkillByBook(
                        game.playerTower[playerIndex],
                        btnIdx,
                        game.towersAbilities[playerIndex][btnIdx]
                    )
                    addTowerSkillByBook(game.playerTower[playerIndex], btnIdx, abils[btnIdx])
                    if (itemSLK.ABILITY_COLOR == "yellow") then
                        heffect.toUnit("war3mapImported\\eff_burst_round_gold.mdl", game.playerTower[playerIndex], 0)
                    elseif (itemSLK.ABILITY_COLOR == "blue") then
                        heffect.toUnit("war3mapImported\\eff_burst_round.mdl", game.playerTower[playerIndex], 0)
                    elseif (itemSLK.ABILITY_COLOR == "purple") then
                        heffect.toUnit("war3mapImported\\eff_burst_round_purple.mdl", game.playerTower[playerIndex], 0)
                    end
                end
            )
        else
            local btnIdx = emptySite
            hmsg.echo00(
                p,
                "兵塔自动挑选了[" ..
                    hColor.yellow(btnIdx) ..
                        "]位置，学习了[" .. hColor.yellow(abils[btnIdx].ABILITY_LEVEL .. "级" .. abils[btnIdx].Name) .. "]"
            )
            delTowerSkillByBook(game.playerTower[playerIndex], btnIdx, game.towersAbilities[playerIndex][btnIdx])
            addTowerSkillByBook(game.playerTower[playerIndex], btnIdx, abils[btnIdx])
            if (itemSLK.ABILITY_COLOR == "yellow") then
                heffect.toUnit("war3mapImported\\eff_burst_round_gold.mdl", game.playerTower[playerIndex], 0)
            elseif (itemSLK.ABILITY_COLOR == "blue") then
                heffect.toUnit("war3mapImported\\eff_burst_round.mdl", game.playerTower[playerIndex], 0)
            elseif (itemSLK.ABILITY_COLOR == "purple") then
                heffect.toUnit("war3mapImported\\eff_burst_round_purple.mdl", game.playerTower[playerIndex], 0)
            end
        end
    elseif (itemSLK.I_TYPE == "effect_model" and itemSLK.INDEX == "超次元套装礼包") then
        local playerIndex = hplayer.index(p)
        --选择套装
        local tz = {}
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzfire") == true) then
            table.insert(tz, "炎炎焚烧套装")
        end
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzgold") == true) then
            table.insert(tz, "金碧辉煌套装")
        end
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzboold") == true) then
            table.insert(tz, "血色炽热套装")
        end
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzdragon") == true) then
            table.insert(tz, "青龙碧翼套装")
        end
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzdark") == true) then
            table.insert(tz, "迷幻黑紫套装")
        end
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzghost") == true) then
            table.insert(tz, "邪鬼怨灵套装")
        end
        if (hdzapi.hasMallItem(hplayer.players[playerIndex], "tzsword") == true) then
            table.insert(tz, "出云剑仙套装")
        end
        if (#tz <= 0) then
            hmsg.echo00(hplayer.players[playerIndex], "您尚未拥有任何套装~")
            return
        end
        hdialog.create(
            hplayer.players[playerIndex],
            {
                title = "选择专属套装",
                buttons = tz
            },
            function(btnIdx)
                --清空之前的装扮
                if (game.playerTowerEffectModel[playerIndex] == nil) then
                    game.playerTowerEffectModel[playerIndex] = {}
                end
                if (#game.playerTowerEffectModel[playerIndex] > 0) then
                    for _, v in ipairs(game.playerTowerEffectModel[playerIndex]) do
                        hskill.del(game.playerTower[playerIndex], v, 0)
                    end
                    game.playerTowerEffectModel[playerIndex] = {}
                end
                local tips
                if (btnIdx == "金碧辉煌套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["金耀翅膀特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["金耀公正特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["金耀天堂特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["金耀精灵特效"].ABILITY_ID)
                    tips = "金耀翅膀、公正光辉、天堂圣音、金色精灵"
                elseif (btnIdx == "迷幻黑紫套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["幻黑翅膀特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["幻黑迷紫特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["幻黑迷阵特效"].ABILITY_ID)
                    tips = "幻黑翅膀、迷紫幻象、迷惑雾阵"
                elseif (btnIdx == "血色炽热套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["血色翅膀特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["血色漩涡特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["血色符文特效"].ABILITY_ID)
                    tips = "血色翅膀、赤红漩涡、祭奠符文"
                elseif (btnIdx == "青龙碧翼套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["青空之翼特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["游龙欢悦特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["青龙吐息特效"].ABILITY_ID)
                    tips = "青空之翼、游龙欢悦、龙腾吐息"
                elseif (btnIdx == "邪鬼怨灵套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["邪鬼怨灵特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["邪鬼阵法特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["邪鬼符文特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["邪鬼之眼特效"].ABILITY_ID)
                    tips = "邪鬼怨灵、邪鬼阵法、超度符文、逗趣鬼眼"
                elseif (btnIdx == "炎炎焚烧套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["炎炎旋风特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["炎炎领域特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["炎炎燃烧特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["炎炎三球特效"].ABILITY_ID)
                    tips = "炎炎旋风、烧灼圈圈、焚烧之火、鬼马火球"
                elseif (btnIdx == "出云剑仙套装") then
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["出云飞剑特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["出云气场特效"].ABILITY_ID)
                    table.insert(game.playerTowerEffectModel[playerIndex], game.effectModel["出云飞龙特效"].ABILITY_ID)
                    tips = "盘旋飞剑、灵剑气场、飞龙在天"
                end
                if (#game.playerTowerEffectModel[playerIndex] > 0) then
                    for _, v in ipairs(game.playerTowerEffectModel[playerIndex]) do
                        hskill.add(game.playerTower[playerIndex], v, 0)
                    end
                    hmsg.echo00(hplayer.players[playerIndex], "成功装扮了：" .. hColor.yellow(tips))
                end
            end
        )
    elseif (itemSLK.I_TYPE == "strategy") then
        --战略物品
        local playerIndex = hplayer.index(p)
        local ii = itemSLK.INDEX
        if (ii == "起死回生药水") then
            heffect.toUnit("war3mapImported\\eff_holy_light2.mdl", game.playerTower[playerIndex])
            hunit.setCurLifePercent(game.playerTower[playerIndex], 100)
        elseif (ii == "天剑切符" or ii == "武神切符" or ii == "变异切符" or ii == "恶魔切符" or ii == "恶灵切符") then
            local ts = {game.playerTower[playerIndex]}
            for i = 1, 4, 1 do
                if (game.playerTowerLink[playerIndex][i] ~= nil) then
                    table.insert(ts, game.playerTowerLink[playerIndex][i].unit)
                end
            end
            heffect.toUnit("war3mapImported\\eff_s_EvilWave_Effect.mdl", game.playerTower[playerIndex])
            if (ii == "天剑切符") then
                for _, u in pairs(ts) do
                    hattr.set(
                        u,
                        30,
                        {
                            attack_damage_type = "+god",
                            attack_green = "+500"
                        }
                    )
                end
            elseif (ii == "武神切符") then
                for _, u in pairs(ts) do
                    hattr.set(
                        u,
                        30,
                        {
                            attack_speed = "+75"
                        }
                    )
                end
            elseif (ii == "变异切符") then
                for _, u in pairs(ts) do
                    hattr.set(
                        u,
                        30,
                        {
                            attack_damage_type = "+fire,water,ice,wind,thunder,soil"
                        }
                    )
                end
            elseif (ii == "恶魔切符") then
                for _, u in pairs(ts) do
                    hattr.set(
                        u,
                        30,
                        {
                            damage_extent = "+33",
                            defend = "-100"
                        }
                    )
                end
            elseif (ii == "恶灵切符") then
                for _, u in pairs(ts) do
                    hattr.set(
                        u,
                        30,
                        {
                            natural_ghost = "+50"
                        }
                    )
                end
            end
            ts = nil
        elseif (ii == "圣杯切符") then
            hplayer.addGoldRatio(p, 15, 90)
            heffect.bindUnit("war3mapImported\\eff_Retribution.mdl", game.playerTower[playerIndex], "origin", 90)
        elseif (ii == "陋室切符") then
            hplayer.addExpRatio(p, 20, 90)
            heffect.bindUnit(
                "war3mapImported\\eff_MysticVeil_Portrait.mdl",
                game.playerTower[playerIndex],
                "origin",
                90
            )
        elseif (ii == "王室切符") then
            hplayer.addGoldRatio(p, 10, 90)
            hplayer.addSellRatio(p, 25, 90)
            heffect.bindUnit(
                "war3mapImported\\eff_Aura_Runica_Con_Fuego.mdl",
                game.playerTower[playerIndex],
                "origin",
                90
            )
        elseif (ii == "锤敕令" or ii == "盾敕令" or ii == "剑敕令" or ii == "斧敕令") then
            local ts = {}
            if (ii == "锤敕令") then
                for pi = 1, 4, 1 do
                    if (playerIndex ~= pi and hplayer.getStatus(p) == hplayer.player_status.gaming) then
                        table.insert(ts, game.playerTower[pi])
                        for i = 1, 4, 1 do
                            if
                                (game.playerTowerLink[pi][i] ~= nil and
                                    his.locust(game.playerTowerLink[pi][i].unit) == false)
                             then
                                table.insert(ts, game.playerTowerLink[pi][i].unit)
                            end
                        end
                    end
                end
                for _, u in pairs(ts) do
                    hskill.swim(
                        {
                            whichUnit = u,
                            during = 10,
                            odds = 999,
                            effect = "war3mapImported\\eff_EarthDetonation.mdl"
                        }
                    )
                end
            elseif (ii == "盾敕令") then
                for pi = 1, 4, 1 do
                    if (playerIndex ~= pi and hplayer.getStatus(p) == hplayer.player_status.gaming) then
                        table.insert(ts, game.playerTower[pi])
                        for i = 1, 4, 1 do
                            if
                                (game.playerTowerLink[pi][i] ~= nil and
                                    his.locust(game.playerTowerLink[pi][i].unit) == false)
                             then
                                table.insert(ts, game.playerTowerLink[pi][i].unit)
                            end
                        end
                    end
                end
                for _, u in pairs(ts) do
                    hskill.swim(
                        {
                            whichUnit = u,
                            during = 10,
                            odds = 100,
                            effect = "war3mapImported\\eff_Arcane_Nova.mdl"
                        }
                    )
                end
            elseif (ii == "剑敕令") then
                for pi = 1, 4, 1 do
                    if (playerIndex ~= pi and hplayer.getStatus(p) == hplayer.player_status.gaming) then
                        table.insert(ts, game.playerCourier[pi])
                    end
                end
                for _, u in pairs(ts) do
                    hskill.swim(
                        {
                            whichUnit = u,
                            during = 10,
                            odds = 999,
                            effect = "war3mapImported\\eff_flame_Great_Sword_Falls.mdl"
                        }
                    )
                end
            elseif (ii == "斧敕令") then
                for pi = 1, 4, 1 do
                    if (playerIndex ~= pi and hplayer.getStatus(p) == hplayer.player_status.gaming) then
                        table.insert(ts, game.playerTower[pi])
                    end
                end
                for _, u in pairs(ts) do
                    hunit.setCurLife(u, hunit.getCurLife(u) * 0.8)
                    heffect.toUnit("war3mapImported\\eff_black_chain_flash.mdl", u, 0)
                end
            end
            ts = nil
        end
    end
end

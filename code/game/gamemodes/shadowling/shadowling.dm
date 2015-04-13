/*

SHADOWLING: A gamemode based on previously-run events

Aliens called shadowlings are on the station.
These shadowlings can 'enthrall' crew members and enslave them.
They also burn in the light but heal rapidly whilst in the dark.
The game will end under two conditions:
	1. The shadowlings die
	2. The emergency shuttle docks at CentCom

Shadowling strengths:
	- The dark
	- Hard vacuum (They are not affected by it)
	- Their thralls who are not harmed by the light
	- Stealth

Shadowling weaknesses:
	- The light
	- Fire
	- Enemy numbers
	- Lasers (Lasers are concentrated light and do more damage)
	- Flashbangs (High stun and high burn damage; if the light stuns humans, you bet your ass it'll hurt the shadowling very much!)

Shadowlings start off disguised as normal crew members, and they only have two abilities: Hatch and Enthrall.
They can still enthrall and perhaps complete their objectives in this form.
Hatch will, after a short time, cast off the human disguise and assume the shadowling's true identity.
They will then assume the normal shadowling form and gain their abilities.

The shadowling will seem OP, and that's because it kinda is. Being restricted to the dark while being alone most of the time is extremely difficult and as such the shadowling needs powerful abilities.
Made by Xhuis

*/



/*
	GAMEMODE
*/


/datum/game_mode
	var/list/datum/mind/shadows = list()
	var/list/datum/mind/thralls = list()
	var/list/shadow_objectives = list()
	var/required_thralls = 15 //How many thralls are needed (hardcoded for now)
	var/shadowling_ascended = 0 //If at least one shadowling has ascended
	var/shadowling_dead = 0 //is shadowling kill


/proc/is_thrall(var/mob/living/M)
	return istype(M) && M.mind && ticker && ticker.mode && (M.mind in ticker.mode.thralls)


/proc/is_shadow_or_thrall(var/mob/living/M)
	return istype(M) && M.mind && ticker && ticker.mode && ((M.mind in ticker.mode.thralls) || (M.mind in ticker.mode.shadows))


/proc/is_shadow(var/mob/living/M)
	return istype(M) && M.mind && ticker && ticker.mode && (M.mind in ticker.mode.shadows)


/datum/game_mode/shadowling
	name = "shadowling"
	config_tag = "shadowling"
	antag_flag = BE_SHADOWLING
	required_players = 30
	required_enemies = 2
	recommended_enemies = 2
	restricted_jobs = list("AI", "Cyborg")
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")

/datum/game_mode/shadowling/announce()
	world << "<b>The current game mode is - Shadowling!</b>"
	world << "<b>There are alien <span class='userdanger'>shadowlings</span> on the station. Crew: Kill the shadowlings before they can eat or enthrall the crew. Shadowlings: Enthrall the crew while remaining in hiding.</b>"

/datum/game_mode/shadowling/pre_setup()
	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	if(config.protect_assistant_from_antagonist)
		restricted_jobs += "Assistant"

	for(var/datum/mind/player in antag_candidates)
		for(var/job in restricted_jobs)
			if(player.assigned_role == job)
				antag_candidates -= player

	var/shadowlings = 2 //How many shadowlings there are; hardcoded to 2

	while(shadowlings)
		var/datum/mind/shadow = pick(antag_candidates)
		shadows += shadow
		antag_candidates -= shadow
		modePlayer += shadow
		shadow.special_role = "Shadowling"
		shadowlings--
	return 1


/datum/game_mode/shadowling/post_setup()
	for(var/datum/mind/shadow in shadows)
		log_game("[shadow.key] (ckey) has been selected as a Shadowling.")
		sleep(10)
		shadow.current << "<br>"
		shadow.current << "<span class='deadsay'><b><font size=3>You are a shadowling!</font></b></span>"
		greet_shadow(shadow)
		finalize_shadowling(shadow)
		process_shadow_objectives(shadow)
		//give_shadowling_abilities(shadow)
	..()
	return

/datum/game_mode/proc/greet_shadow(var/datum/mind/shadow)
	shadow.current << "<b>Currently, you are disguised as an employee aboard [world.name].</b>"
	shadow.current << "<b>In your limited state, you have three abilities: Enthrall, Hatch, and Hivemind Commune.</b>"
	shadow.current << "<b>If you are new to shadowling, or want to read about abilities, check the wiki page at https://tgstation13.org/wiki/Shadowling</b><br>"


/datum/game_mode/proc/process_shadow_objectives(var/datum/mind/shadow_mind)
	var/objective = "enthrall" //may be devour later, but for now it seems murderbone-y

	if(objective == "enthrall")
		var/objective_explanation = "Ascend to your true form by use of the Ascendance ability. This may only be used with [required_thralls] collective thralls, while hatched, and is unlocked with the Collective Mind ability."
		shadow_objectives += "enthrall"
		shadow_mind.memory += "<b>Objective #1</b>: [objective_explanation]"
		shadow_mind.current << "<b>Objective #1</b>: [objective_explanation]<br>"


/datum/game_mode/proc/finalize_shadowling(var/datum/mind/shadow_mind)
	var/mob/living/carbon/human/S = shadow_mind.current
	shadow_mind.current.verbs += /mob/living/carbon/human/proc/shadowling_hatch
	shadow_mind.spell_list += new /obj/effect/proc_holder/spell/targeted/enthrall
	shadow_mind.spell_list += new /obj/effect/proc_holder/spell/targeted/shadowling_hivemind
	if(shadow_mind.assigned_role == "Clown")
		S << "<span class='notice'>Your alien nature has allowed you to overcome your clownishness.</span>"
		S.dna.remove_mutation(CLOWNMUT)

/datum/game_mode/proc/add_thrall(datum/mind/new_thrall_mind)
	if (!istype(new_thrall_mind))
		return 0
	if(!(new_thrall_mind in thralls))
		thralls += new_thrall_mind
		new_thrall_mind.current.attack_log += "\[[time_stamp()]\] <span class='danger'>Became a thrall</span>"
		return 1



/*
	GAME FINISH CHECKS
*/


/datum/game_mode/shadowling/check_finished()
	var/shadows_alive = 0 //and then shadowling was kill
	for(var/datum/mind/shadow in shadows) //but what if shadowling was not kill?
		if(!istype(shadow.current,/mob/living/carbon/human) && !istype(shadow.current,/mob/living/simple_animal/ascendant_shadowling))
			continue
		if(shadow.current.stat == DEAD)
			continue
		shadows_alive++
	if(shadows_alive)
		return ..()
	else
		shadowling_dead = 1 //but shadowling was kill :(
		return 1


/datum/game_mode/shadowling/proc/check_shadow_victory()
	var/success = 0 //Did they win?
	if(shadow_objectives.Find("enthrall"))
		success = shadowling_ascended
	return success


/datum/game_mode/shadowling/declare_completion()
	if(check_shadow_victory() && SSshuttle.emergency.mode >= SHUTTLE_ESCAPE) //Doesn't end instantly - this is hacky and I don't know of a better way ~X
		world << "<font size=3 color=green><b>The shadowlings have ascended and taken over the station!</FONT></b></span>"
	else if(shadowling_dead && !check_shadow_victory()) //If the shadowlings have ascended, they can not lose the round
		world << "<span class='danger'><font size=3><b>The shadowlings have been killed by the crew!</b></FONT></span>"
	else if(!check_shadow_victory() && SSshuttle.emergency.mode >= SHUTTLE_ESCAPE)
		world << "<span class='danger'><font size=3><b>The crew has escaped the station before the shadowlings could ascend!</b></FONT></span>"
	..()
	return 1


/datum/game_mode/proc/auto_declare_completion_shadowling()
	var/text = ""
	if(shadows.len)
		text += "<br><font size=2><b>The shadowlings were:</b></font>"
		for(var/datum/mind/shadow in shadows)
			text += printplayer(shadow)
		if(thralls.len)
			text += "<br><font size=2><b>The thralls were:</b></font>"
			for(var/datum/mind/thrall in thralls)
				text += printplayer(thrall)
	else
		world << "<font size=3>Round-end code broke! Please report this and its circumstances on GitHub at https://github.com/tgstation/-tg-station/issues</font>"
	text += "<br>"
	world << text


/*
	MISCELLANEOUS
*/


/datum/species/shadow/ling
	//Normal shadowpeople but with enhanced effects
	name = "Shadowling"
	id = "shadowling"
	say_mod = "chitters"
	specflags = list(NOBREATH,NOBLOOD,RADIMMUNE,NOGUNS) //Can't use guns due to muzzle flash
	burnmod = 2 //2x burn damage lel
	heatmod = 2

/datum/species/shadow/ling/spec_life(mob/living/carbon/human/H)
	//H.shadowling_status = 1 //If they are affected more strongly by flashes and stuff
	var/light_amount = 0
	H.nutrition = NUTRITION_LEVEL_WELL_FED //i aint never get hongry
	if(isturf(H.loc)) //Copypasta
		var/turf/T = H.loc
		var/area/A = T.loc
		if(A)
			if(A.lighting_use_dynamic)	light_amount = T.lighting_lumcount
			else						light_amount =  10
		if(light_amount > 2) //Rapid death while in the light, countered by...
			H.take_overall_damage(0,6)
			H << "<span class='userdanger'>The light burns you!</span>"
			H << 'sound/weapons/sear.ogg'
		else if (light_amount < 2)  //...extreme benefits while in the dark
			H.heal_overall_damage(5,3)
			H.adjustToxLoss(-3)
			H.SetWeakened(0)
			H.SetStunned(0)

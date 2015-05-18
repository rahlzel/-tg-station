//gang.dm
//Gang War Game Mode

/datum/game_mode
	var/list/datum/mind/A_gang = list() //gang A Members
	var/list/datum/mind/B_gang = list() //gang B Members
	var/list/datum/mind/A_bosses = list() //gang A Bosses
	var/list/datum/mind/B_bosses = list() //gang B Bosses
	var/obj/item/device/gangtool/A_tools = list()
	var/obj/item/device/gangtool/B_tools = list()
	var/datum/gang_points/gang_points
	var/list/A_territory = list()
	var/list/B_territory = list()
	var/list/A_territory_new = list()
	var/list/A_territory_lost = list()
	var/list/B_territory_new = list()
	var/list/B_territory_lost = list()

/datum/game_mode/gang
	name = "gang war"
	config_tag = "gang"
	antag_flag = BE_GANG
	restricted_jobs = list("Security Officer", "Warden", "Detective", "AI", "Cyborg","Captain", "Head of Personnel", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")
	required_players = 20
	required_enemies = 2
	recommended_enemies = 2
	enemy_minimum_age = 14
	var/finished = 0
	var/goal_scalar = 0.5 //Goal = Total territories x goal_scalar

///////////////////////////
//Announces the game type//
///////////////////////////
/datum/game_mode/gang/announce()
	world << "<B>The current game mode is - Gang War!</B>"
	world << "<B>A violent turf war has erupted on the station!<BR>Gangsters -  Take over the station by claiming more than [round(100*goal_scalar,1)]% of the station! <BR>Crew - The gangs will try to keep you on the station. Successfully evacuate the station to win!</B>"


///////////////////////////////////////////////////////////////////////////////
//Gets the round setup, cancelling if there's not enough players at the start//
///////////////////////////////////////////////////////////////////////////////
/datum/game_mode/gang/pre_setup()
	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	if(config.protect_assistant_from_antagonist)
		restricted_jobs += "Assistant"

	if(antag_candidates.len >= 2)
		assign_bosses()

	if(!A_bosses.len || !B_bosses.len)
		return 0

	return 1


/datum/game_mode/gang/post_setup()
	spawn(rand(10,100))
		for(var/datum/mind/boss_mind in A_bosses)
			update_gang_icons_added(boss_mind, "A")
			forge_gang_objectives(boss_mind, "A")
			greet_gang(boss_mind)
			equip_gang(boss_mind.current)

		for(var/datum/mind/boss_mind in B_bosses)
			update_gang_icons_added(boss_mind, "B")
			forge_gang_objectives(boss_mind, "B")
			greet_gang(boss_mind)
			equip_gang(boss_mind.current)

	modePlayer += A_bosses
	modePlayer += B_bosses
	..()

/datum/game_mode/gang/proc/assign_bosses()
	var/datum/mind/boss = pick(antag_candidates)
	A_bosses += boss
	antag_candidates -= boss
	boss.special_role = "[gang_name("A")] Gang (A) Boss"
	boss.restricted_roles = restricted_jobs
	log_game("[boss.key] has been selected as the boss for the [gang_name("A")] Gang (A)")

	boss = pick(antag_candidates)
	B_bosses += boss
	antag_candidates -= boss
	boss.special_role = "[gang_name("B")] Gang (B) Boss"
	boss.restricted_roles = restricted_jobs
	log_game("[boss.key] has been selected as the boss for the [gang_name("B")] Gang (B)")

/datum/game_mode/proc/forge_gang_objectives(var/datum/mind/boss_mind)
	var/datum/objective/rival_obj = new
	rival_obj.owner = boss_mind
	rival_obj.explanation_text = "Claim more than 50% the station before the [(boss_mind in A_bosses) ? gang_name("B") : gang_name("A")] Gang does."
	boss_mind.objectives += rival_obj


/datum/game_mode/proc/greet_gang(var/datum/mind/boss_mind, var/you_are=1)
	var/obj_count = 1
	if (you_are)
		boss_mind.current << "<FONT size=3 color=red><B>You are the founding member of the [(boss_mind in A_bosses) ? gang_name("A") : gang_name("B")] Gang!</B></FONT>"
	for(var/datum/objective/objective in boss_mind.objectives)
		boss_mind.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++

///////////////////////////////////////////////////////////////////////////
//This equips the bosses with their gear, and makes the clown not clumsy//
///////////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/equip_gang(mob/living/carbon/human/mob)
	if(!istype(mob))
		return

	if (mob.mind)
		if (mob.mind.assigned_role == "Clown")
			mob << "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself."
			mob.dna.remove_mutation(CLOWNMUT)

	var/obj/item/weapon/pen/gang/T = new(mob)
	var/obj/item/device/gangtool/gangtool = new(mob)
	var/obj/item/toy/crayon/spraycan/gang/SC = new(mob)

	var/list/slots = list (
		"backpack" = slot_in_backpack,
		"left pocket" = slot_l_store,
		"right pocket" = slot_r_store,
		"left hand" = slot_l_hand,
		"right hand" = slot_r_hand,
	)

	. = 0

	var/where = mob.equip_in_one_of_slots(gangtool, slots)
	if (!where)
		mob << "Your Syndicate benefactors were unfortunately unable to get you a Gangtool."
	else
		gangtool.register_device(mob)
		mob << "The <b>Gangtool</b> in your [where] will allow you to use your influence to purchase items and prevent the station from evacuating before you can take over. Use it to recall the emergency shuttle from anywhere on the station."
		mob << "You can also promote your gang members to <b>lieutenant</b> by giving them an unregistered gangtool. Lieutenants cannot be deconverted and are able to use recruitment pens and gangtools."
		. += 1

	var/where2 = mob.equip_in_one_of_slots(T, slots)
	if (!where2)
		mob << "Your Syndicate benefactors were unfortunately unable to get you a recruitment pen to start."
	else
		mob << "The <b>recruitment pen</b> in your [where2] will help you get your gang started. Use it on unsuspecting crew members to recruit them."
		. += 1

	var/where3 = mob.equip_in_one_of_slots(SC, slots)
	if (!where3)
		mob << "Your Syndicate benefactors were unfortunately unable to get you a territory spraycan to start."
	else
		mob << "The <b>territory spraycan</b> in your [where3] can be used to claim areas of the station for your gang. The more territory your gang controls, the more influence you get. Distribute these to your gangsters to grow your influence faster."
		. += 1
	mob.update_icons()

	return .

/////////////////////////////////////////////
//Checks if the either gang have won or not//
/////////////////////////////////////////////
/datum/game_mode/gang/check_win()
	if(A_territory.len > (start_state.num_territories * goal_scalar))
		finished = "A" //Gang A wins
	else if(B_territory.len > (start_state.num_territories * goal_scalar))
		finished = "B" //Gang B wins

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/gang/check_finished()
	if(finished)
		return 1
	return ..() //Check for evacuation/nuke

///////////////////////////////////////////
//Deals with converting players to a gang//
///////////////////////////////////////////
/datum/game_mode/proc/add_gangster(datum/mind/gangster_mind, var/gang, var/check = 1)
	if(check && isloyal(gangster_mind.current)) //Check to see if the potential gangster is implanted
		return 0
	if(gangster_mind in (A_bosses | A_gang | B_bosses | B_gang))
		return 0
	if(gang == "A")
		A_gang += gangster_mind
	else
		B_gang += gangster_mind
	if(check)
		if(iscarbon(gangster_mind.current))
			var/mob/living/carbon/carbon_mob = gangster_mind.current
			carbon_mob.silent = max(carbon_mob.silent, 5)
			carbon_mob.flash_eyes(1, 1)
		gangster_mind.current.Stun(5)
	gangster_mind.current << "<FONT size=3 color=red><B>You are now a member of the [gang=="A" ? gang_name("A") : gang_name("B")] Gang!</B></FONT>"
	gangster_mind.current << "<font color='red'>Help your bosses take over the station by claiming territory with <b>special spraycans</b> only they can provide. Simply spray on any unclaimed area of the station.</font>"
	gangster_mind.current << "<font color='red'>You can identify your bosses by their <b>red \[G\] icon</b>.</font>"
	gangster_mind.current.attack_log += "\[[time_stamp()]\] <font color='red'>Has been converted to the [gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"]!</font>"
	gangster_mind.special_role = "[gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"]"
	update_gang_icons_added(gangster_mind,gang)
	return 1
////////////////////////////////////////////////////////////////////
//Deals with players reverting to neutral (Not a gangster anymore)//
////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/remove_gangster(datum/mind/gangster_mind, var/beingborged, var/silent, var/exclude_bosses=0)
	var/gang

	if(!exclude_bosses)
		if(gangster_mind in A_bosses)
			A_bosses -= gangster_mind
			gang = "A"

		if(gangster_mind in B_bosses)
			B_bosses -= gangster_mind
			gang = "B"

	if(gangster_mind in A_gang)
		A_gang -= gangster_mind
		gang = "A"

	if(gangster_mind in B_gang)
		B_gang -= gangster_mind
		gang = "B"

	if(!gang) //not a valid gangster
		return

	gangster_mind.special_role = null
	if(silent < 2)
		gangster_mind.current.attack_log += "\[[time_stamp()]\] <font color='red'>Has reformed and defected from the [gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"]!</font>"

		if(beingborged)
			if(!silent)
				gangster_mind.current.visible_message("The frame beeps contentedly from the MMI before initalizing it.")
			gangster_mind.current << "<FONT size=3 color=red><B>The frame's firmware detects and deletes your criminal behavior! You are no longer a gangster!</B></FONT>"
			message_admins("[key_name_admin(gangster_mind.current)] <A HREF='?_src_=holder;adminmoreinfo=\ref[gangster_mind.current]'>?</A> has been borged while being a member of the [gang=="A" ? "[gang_name("A")] Gang (A)" : "[gang_name("B")] Gang (B)"] Gang. They are no longer a gangster.")
		else
			if(!silent)
				gangster_mind.current.Paralyse(5)
				gangster_mind.current.visible_message("<FONT size=3><B>[gangster_mind.current] looks like they've given up the life of crime!<B></font>")
			gangster_mind.current << "<FONT size=3 color=red><B>You have been reformed! You are no longer a gangster!</B><BR>You try as hard as you can, but you can't seem to recall any of the identities of your former gangsters...</FONT>"

	update_gang_icons_removed(gangster_mind, gang)

///////////////////////
//Add/remove gang HUD//
///////////////////////
/datum/game_mode/proc/get_gang_hud(var/gang)
	var/datum/atom_hud/antag/ganghud = null
	switch(gang)
		if("A") ganghud = huds[ANTAG_HUD_GANG_A]
		if("B") ganghud = huds[ANTAG_HUD_GANG_B]
	return ganghud

/datum/game_mode/proc/get_gang_bosses(var/gang)
	var/bosses = null
	switch(gang)
		if("A") bosses = A_bosses
		if("B") bosses = B_bosses
	return bosses

/datum/game_mode/proc/update_gang_icons_added(datum/mind/recruit_mind, var/gang)
	var/datum/atom_hud/antag/ganghud = get_gang_hud(gang)
	var/bosses = get_gang_bosses(gang)
	if(!ganghud)
		ERROR("Invalid gang in update_gang_icons_added(): [gang]")

	ganghud.join_hud(recruit_mind.current)
	set_antag_hud(recruit_mind.current, ((recruit_mind in bosses) ? "gang_boss" : "gangster"))

/datum/game_mode/proc/update_gang_icons_removed(datum/mind/defector_mind, var/gang)
	var/datum/atom_hud/antag/ganghud = get_gang_hud(gang)
	if(!ganghud)
		ERROR("Invalid gang in update_gang_icons_removed(): [gang]")

	ganghud.leave_hud(defector_mind.current)
	set_antag_hud(defector_mind.current, null)


//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relavent information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/gang/declare_completion()
	if(!finished)
		world << "<FONT size=3 color=red><B>The station was [station_was_nuked ? "destroyed!" : "evacuated before either gang could claim it!"]</B></FONT>"
	else
		world << "<FONT size=3 color=red><B>The [finished=="A" ? gang_name("A") : gang_name("B")] Gang has claimed over [round(100*goal_scalar,1)]% of the station and has assumed control!</B></FONT>"
	..()
	return 1

/datum/game_mode/proc/auto_declare_completion_gang()
	var/winner
	var/datum/game_mode/gang/game_mode = ticker.mode
	if(istype(game_mode))
		if(game_mode.finished)
			winner = game_mode.finished
		else
			winner = "Draw"

	if(A_bosses.len || A_gang.len)
		if(winner)
			world << "<br><b>The [gang_name("A")] Gang was [winner=="A" ? "<font color=green>victorious</font>" : "<font color=red>defeated</font>"] with [round((ticker.mode.A_territory.len/start_state.num_territories)*100, 1)]% control of the station!</b>"
		world << "<br>The [gang_name("A")] Gang Bosses were:"
		gang_membership_report(A_bosses)
		world << "<br>The [gang_name("A")] Gangsters were:"
		gang_membership_report(A_gang)
		world << "<br>"

	if(B_bosses.len || B_gang.len)
		if(winner)
			world << "<br><b>The [gang_name("B")] Gang was [winner=="B" ? "<font color=green>victorious</font>" : "<font color=red>defeated</font>"] with [round((ticker.mode.B_territory.len/start_state.num_territories)*100, 1)]% control of the station!</b></b>"
		world << "<br>The [gang_name("B")] Gang Bosses were:"
		gang_membership_report(B_bosses)
		world << "<br>The [gang_name("B")] Gangsters were:"
		gang_membership_report(B_gang)
		world << "<br>"

/datum/game_mode/proc/gang_membership_report(var/list/membership)
	var/text = ""
	for(var/datum/mind/gang_mind in membership)
		text += "<br><b>[gang_mind.key]</b> was <b>[gang_mind.name]</b> ("
		if(gang_mind.current)
			if(gang_mind.current.stat == DEAD || isbrain(gang_mind.current))
				text += "died"
			else if(gang_mind.current.z != ZLEVEL_STATION)
				text += "fled the station"
			else
				text += "survived"
			if(gang_mind.current.real_name != gang_mind.name)
				text += " as <b>[gang_mind.current.real_name]</b>"
		else
			text += "body destroyed"
		text += ")"

	world << text


//////////////////////////////////////////////////////////
//Handles influence, territories, and the victory checks//
//////////////////////////////////////////////////////////

/datum/gang_points
	var/A = 30
	var/B = 30
	var/next_point_interval = 1800
	var/next_point_time

/datum/gang_points/proc/start()
	next_point_time = world.time + next_point_interval
	spawn(next_point_interval)
		income()

/datum/gang_points/proc/income()
	var/A_added_names = ""
	var/B_added_names = ""
	var/A_lost_names = ""
	var/B_lost_names = ""

	//Process lost territories
	for(var/area in ticker.mode.A_territory_lost)
		if(A_lost_names == "")
			A_lost_names += ":<br>"
		else
			A_lost_names += ", "
		A_lost_names += "[ticker.mode.A_territory_lost[area]], "
		ticker.mode.A_territory -= area

	for(var/area in ticker.mode.B_territory_lost)
		if(B_lost_names == "")
			B_lost_names += ":<br>"
		else
			B_lost_names += ", "
		B_lost_names += "[ticker.mode.B_territory_lost[area]], "
		ticker.mode.B_territory -= area

	//Calculate and report influence growth
	ticker.mode.message_gangtools(ticker.mode.A_tools,"<b>[gang_name("A")] Gang Status Report:</b>")
	var/A_new = min(999,A + 15 + ticker.mode.A_territory.len)
	var/A_message = ""
	if(A_new != A)
		A_message += "Your gang has gained <b>[A_new - A] Influence</b> for holding on to [ticker.mode.A_territory.len] territories."
	if(A_new == 999)
		A_message += " You cannot gain any more influence without spending some with this device."
	A = A_new
	ticker.mode.message_gangtools(ticker.mode.A_tools,A_message,0)

	ticker.mode.message_gangtools(ticker.mode.B_tools,"<b>[gang_name("B")] Gang Status Report:</b>")
	var/B_new = min(999,B + 15 + ticker.mode.B_territory.len)
	var/B_message = ""
	if(B_new != B)
		B_message += "Your gang has gained <b>[B_new - B] Influence</b> for holding on to [ticker.mode.B_territory.len] territories."
	if(B_new == 999)
		B_message += " You cannot gain any more influence without spending some with this device."
	B = B_new
	ticker.mode.message_gangtools(ticker.mode.B_tools,B_message,0)


	//Remove territories they already own from the buffer, so if they got tagged over, they can still earn income if they tag it back before the next status report
	ticker.mode.A_territory_new -= ticker.mode.A_territory
	ticker.mode.B_territory_new -= ticker.mode.B_territory

	//Process new territories
	for(var/area in ticker.mode.A_territory_new)
		if(A_added_names == "")
			A_added_names += ":<br>"
		else
			A_added_names += ", "
		A_added_names += "[ticker.mode.A_territory_new[area]]"
		ticker.mode.A_territory += area

	for(var/area in ticker.mode.B_territory_new)
		if(B_added_names == "")
			B_added_names += ":<br>"
		else
			B_added_names += ", "
		B_added_names += "[ticker.mode.B_territory_new[area]]"
		ticker.mode.B_territory += area

	//Report territory changes
	ticker.mode.message_gangtools(ticker.mode.A_tools,"<b>[ticker.mode.A_territory_new.len] new territories</b>[A_added_names]",0)
	ticker.mode.message_gangtools(ticker.mode.B_tools,"<b>[ticker.mode.B_territory_new.len] new territories</b>[B_added_names]",0,)
	ticker.mode.message_gangtools(ticker.mode.A_tools,"<b>[ticker.mode.A_territory_lost.len] territories lost</b>[A_lost_names]",0,1)
	ticker.mode.message_gangtools(ticker.mode.B_tools,"<b>[ticker.mode.B_territory_lost.len] territories lost</b>[B_lost_names]",0,1)

	//Clear the lists
	ticker.mode.A_territory_new = list()
	ticker.mode.B_territory_new = list()
	ticker.mode.A_territory_lost = list()
	ticker.mode.B_territory_lost = list()

	var/A_control = round((ticker.mode.A_territory.len/start_state.num_territories)*100, 1)
	var/B_control = round((ticker.mode.B_territory.len/start_state.num_territories)*100, 1)
	ticker.mode.message_gangtools((ticker.mode.A_tools),"Your gang now has <b>[A_control]% control</b> of the station.",0)
	ticker.mode.message_gangtools((ticker.mode.A_tools),"The [gang_name("B")] Gang has <b>[B_control]% control</b> of the station.",0,1)
	ticker.mode.message_gangtools((ticker.mode.B_tools),"Your gang now has <b>[B_control]% control</b> of the station.",0)
	ticker.mode.message_gangtools((ticker.mode.B_tools),"The [gang_name("A")] Gang has <b>[A_control]% control</b> of the station.",0,1)

	//Victory check
	ticker.mode.check_win()

	//Restart the counter
	start()


////////////////////////////////////////////////
//Sends a message to the boss via his gangtool//
////////////////////////////////////////////////

/datum/game_mode/proc/message_gangtools(var/list/gangtools,var/message,var/beep=1,var/warning)
	if(!gangtools.len || !message)
		return
	for(var/obj/item/device/gangtool/tool in gangtools)
		var/mob/living/mob = get(tool.loc,/mob/living)
		if(mob && mob.mind)
			if(((tool.gang == "A") && ((mob.mind in A_gang) || (mob.mind in A_bosses))) || ((tool.gang == "B") && ((mob.mind in B_gang) || (mob.mind in B_bosses))))
				mob << "<span class='[warning ? "warning" : "notice"]'>\icon[tool] [message]</span>"
				if(beep)
					playsound(mob.loc, 'sound/machines/twobeep.ogg', 50, 1)
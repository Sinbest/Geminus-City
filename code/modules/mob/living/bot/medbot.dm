/mob/living/bot/medbot
	name = "Medibot"
	desc = "A little medical robot. He looks somewhat underwhelmed."
	icon_state = "medibot0"
	req_one_access = list(access_robotics, access_medical)
	botcard_access = list(access_medical, access_morgue, access_surgery, access_chemistry, access_virology, access_genetics)

	var/skin = null //Set to "tox", "ointment" or "o2" for the other two firstaid kits.

	on = FALSE
	locked = FALSE

	//AI vars
	var/last_newpatient_speak = 0
	var/vocal = 1

	//Healing vars
	var/obj/item/weapon/reagent_containers/glass/reagent_glass = null //Can be set to draw from this for reagents.
	var/injection_amount = 15 //How much reagent do we inject at a time?
	var/heal_threshold = 10 //Start healing when they have this much damage in a category
	var/use_beaker = 0 //Use reagents in beaker instead of default treatment agents.
	var/treatment_brute = "tricordrazine"
	var/treatment_oxy = "tricordrazine"
	var/treatment_fire = "tricordrazine"
	var/treatment_tox = "tricordrazine"
	var/treatment_virus = "spaceacillin"
	var/treatment_emag = "toxin"
	var/declare_treatment = 0 //When attempting to treat a patient, should it notify everyone wearing medhuds?

// Money stuff
	var/paid_time
	var/paying_time
	var/timing
	var/department_account = "Public Healthcare"

/mob/living/bot/medbot/mysterious
	name = "\improper Mysterious Medibot"
	desc = "International Medibot of mystery."
	skin = "bezerk"
	treatment_brute		= "bicaridine"
	treatment_fire		= "dermaline"
	treatment_oxy		= "dexalin"
	treatment_tox		= "anti_toxin"
	paid_time = INFINITY
	on = TRUE

/mob/living/bot/medbot/handleIdle()
	if(vocal && prob(1))
		var/message_options = list(
			"Radar, put a mask on!" = 'sound/voice/medbot/mradar.ogg',
			"There's always a catch, and it's the best there is." = 'sound/voice/medbot/mcatch.ogg',
			"Avaricious!" = 'sound/machines/buzzbeep.ogg', //placeholder until we can get the voice thing. Why don't they just use dynamic voice gen from VOX?
			"I knew it, I should've been a plastic surgeon." = 'sound/voice/medbot/msurgeon.ogg',
			"What kind of medbay is this? Everyone's dropping like flies." = 'sound/voice/medbot/mflies.ogg',
			"Delicious!" = 'sound/voice/medbot/mdelicious.ogg'
			)
		var/message = pick(message_options)
		say(message)
		playsound(src.loc, message_options[message], 50, 0)

/mob/living/bot/medbot/handleAdjacentTarget()
	UnarmedAttack(target)

/mob/living/bot/medbot/lookForTargets()
	for(var/mob/living/carbon/human/H in view(7, src)) // Time to find a patient!
		if(confirmTarget(H))
			target = H
			if(last_newpatient_speak + 30 SECONDS < world.time)
				if(vocal)
					var/message_options = list(
						"Hey, [H.name]! Hold on, I'm coming." = 'sound/voice/medbot/mcoming.ogg',
						"Wait [H.name]! I want to help!" = 'sound/voice/medbot/mhelp.ogg',
						"[H.name], you appear to be injured!" = 'sound/voice/medbot/minjured.ogg'
						)
					var/message = pick(message_options)
					say(message)
					playsound(loc, message_options[message], 50, 0)
				custom_emote(1, "points at [H.name].")
				last_newpatient_speak = world.time
			break

/mob/living/bot/medbot/UnarmedAttack(var/mob/living/carbon/human/H)
	if(!..())
		return

	if(!on)
		return

	if(!istype(H))
		return

	if(busy)
		return

	var/t = confirmTarget(H)
	if(!t)
		return

	visible_message("<span class='warning'>[src] is trying to inject [H]!</span>")
	if(declare_treatment)
		var/area/location = get_area(src)
		global_announcer.autosay("[src] is treating <b>[H]</b> in <b>[location]</b>", "[src]", "Medical")
	busy = 1
	update_icons()
	if(do_mob(src, H, 30))
		if(t == 1)
			reagent_glass.reagents.trans_to_mob(H, injection_amount, CHEM_BLOOD)
		else
			H.reagents.add_reagent(t, injection_amount)
		visible_message("<span class='warning'>[src] injects [H] with the syringe!</span>")

	if(H.stat == DEAD) // This is down here because this proc won't be called again due to losing a target because of parent AI loop.
		target = null
		if(vocal)
			var/death_messages = list(
				"No! Stay with me!" = 'sound/voice/medbot/mno.ogg',
				"Live, damnit! LIVE!" = 'sound/voice/medbot/mlive.ogg',
				"I... I've never lost a patient before. Not today, I mean." = 'sound/voice/medbot/mlost.ogg'
				)
			var/message = pick(death_messages)
			say(message)
			playsound(src.loc, death_messages[message], 50, 0)

	// This is down here for the same reason as above.
	else
		t = confirmTarget(H)
		if(!t)
			target = null
			if(vocal)
				var/possible_messages = list(
					"All patched up!" = 'sound/voice/medbot/mpatchedup.ogg',
					"An apple a day keeps me away." = 'sound/voice/medbot/mapple.ogg',
					"Feel better soon!" = 'sound/voice/medbot/mfeelbetter.ogg'
					)
				var/message = pick(possible_messages)
				say(message)
				playsound(src.loc, possible_messages[message], 50, 0)

	busy = 0
	update_icons()

/mob/living/bot/medbot/update_icons()
	overlays.Cut()
	if(skin)
		overlays += image('icons/obj/aibots.dmi', "medskin_[skin]")
	if(busy)
		icon_state = "medibots"
	else
		icon_state = "medibot[on]"

/mob/living/bot/medbot/attack_hand(var/mob/user)
	var/dat
	dat += "<TT><B>Automatic Medical Unit v1.0</B></TT><BR><BR>"
	dat += "Status: [on]</A><BR>"
	dat += "Maintenance panel is [open ? "opened" : "closed"]<BR>"
	dat += "Beaker: "
	if (reagent_glass)
		dat += "<A href='?src=\ref[src];eject=1'>Loaded \[[reagent_glass.reagents.total_volume]/[reagent_glass.reagents.maximum_volume]\]</a><BR>"
	else
		dat += "None Loaded<BR>"


	dat += "<TT>Pay For Time  "
	dat += "<a href='?src=\ref[src];pay_for_time=-5'>--</a> "
	dat += "<a href='?src=\ref[src];pay_for_time=-1'>-</a> "
	dat += "[paying_time] "
	dat += "<a href='?src=\ref[src];pay_for_time=+1'>+</a> "
	dat += "<a href='?src=\ref[src];pay_for_time=+5'>++</a>"
	dat += "</TT><br>"
	dat += "Time Left: [paid_time]</A><BR>"

	dat += "<TT>Healing Threshold: "
	dat += "<a href='?src=\ref[src];adj_threshold=-10'>--</a> "
	dat += "<a href='?src=\ref[src];adj_threshold=-5'>-</a> "
	dat += "[heal_threshold] "
	dat += "<a href='?src=\ref[src];adj_threshold=5'>+</a> "
	dat += "<a href='?src=\ref[src];adj_threshold=10'>++</a>"
	dat += "</TT><br>"

	dat += "<TT>Injection Level: "
	dat += "<a href='?src=\ref[src];adj_inject=-5'>-</a> "
	dat += "[injection_amount] "
	dat += "<a href='?src=\ref[src];adj_inject=5'>+</a> "
	dat += "</TT><br>"

	dat += "Reagent Source: "
	dat += "<a href='?src=\ref[src];use_beaker=1'>[use_beaker ? "Loaded Beaker (When available)" : "Internal Synthesizer"]</a><br>"

	dat += "Treatment report is [declare_treatment ? "on" : "off"]. <a href='?src=\ref[src];declaretreatment=[1]'>Toggle</a><br>"

	dat += "The speaker switch is [vocal ? "on" : "off"]. <a href='?src=\ref[src];togglevoice=[1]'>Toggle</a><br>"

	user << browse("<HEAD><TITLE>Medibot v1.0 controls</TITLE></HEAD>[dat]", "window=automed")
	onclose(user, "automed")
	return

/mob/living/bot/medbot/attackby(var/obj/item/O, var/mob/user)
	if(istype(O, /obj/item/weapon/reagent_containers/glass))
		if(locked)
			user << "<span class='notice'>You cannot insert a beaker because the panel is locked.</span>"
			return
		if(!isnull(reagent_glass))
			user << "<span class='notice'>There is already a beaker loaded.</span>"
			return

		user.drop_item()
		O.loc = src
		reagent_glass = O
		user << "<span class='notice'>You insert [O].</span>"
		return

//moneystuff
	if(department_accounts["Public Healthcare"] && !department_accounts["Public Healthcare"].suspended)
		var/paid = 0

//coin operated only
		if(istype(O, /obj/item/weapon/spacecash))
			var/obj/item/weapon/spacecash/C = O
			paid = pay_with_cash(C, user)

		if(paid)
			paid_time = paying_time
			turn_on()
			return paying_time = 0
// end money
	else
		..()

/mob/living/bot/medbot/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	add_fingerprint(usr)

	if (href_list["pay_for_time"])
		var/adjust_num = text2num(href_list["pay_for_time"])
		paying_time += adjust_num
		if(paying_time < 0)
			paying_time = 0

	else if(href_list["adj_threshold"])
		var/adjust_num = text2num(href_list["adj_threshold"])
		heal_threshold += adjust_num
		if(heal_threshold < 5)
			heal_threshold = 5
		if(heal_threshold > 75)
			heal_threshold = 75

	else if(href_list["adj_inject"])
		var/adjust_num = text2num(href_list["adj_inject"])
		injection_amount += adjust_num
		if(injection_amount < 5)
			injection_amount = 5
		if(injection_amount > 15)
			injection_amount = 15

	else if(href_list["use_beaker"])
		use_beaker = !use_beaker

	else if (href_list["eject"] && (!isnull(reagent_glass)))
		if(!locked)
			reagent_glass.loc = get_turf(src)
			reagent_glass = null
		else
			usr << "<span class='notice'>You cannot eject the beaker because the panel is locked.</span>"

	else if (href_list["togglevoice"])
		vocal = !vocal

	else if (href_list["declaretreatment"])
		declare_treatment = !declare_treatment

	attack_hand(usr)
	return

/mob/living/bot/medbot/emag_act(var/remaining_uses, var/mob/user)
	. = ..()
	if(!emagged)
		if(user)
			user << "<span class='warning'>You short out [src]'s reagent synthesis circuits.</span>"
		visible_message("<span class='warning'>[src] buzzes oddly!</span>")
		flick("medibot_spark", src)
		target = null
		busy = 0
		emagged = 1
		update_icons()
		. = 1
	ignore_list |= user

/mob/living/bot/medbot/explode()
	on = 0
	visible_message("<span class='danger'>[src] blows apart!</span>")
	var/turf/Tsec = get_turf(src)

	new /obj/item/weapon/storage/firstaid(Tsec)
	new /obj/item/device/assembly/prox_sensor(Tsec)
	new /obj/item/device/healthanalyzer(Tsec)
	if (prob(50))
		new /obj/item/robot_parts/l_arm(Tsec)

	if(reagent_glass)
		reagent_glass.loc = Tsec
		reagent_glass = null

	if(emagged && prob(25))
		playsound(src.loc, 'sound/voice/medbot/minsult.ogg', 50, 0)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()
	qdel(src)
	return

/mob/living/bot/medbot/confirmTarget(var/mob/living/carbon/human/H)
	if(!..())
		return 0

	if(H.stat == DEAD) // He's dead, Jim
		return 0

	if(H.suiciding)
		return 0

	if(emagged)
		return treatment_emag

	// If they're injured, we're using a beaker, and they don't have on of the chems in the beaker
	if(reagent_glass && use_beaker && ((H.getBruteLoss() >= heal_threshold) || (H.getToxLoss() >= heal_threshold) || (H.getToxLoss() >= heal_threshold) || (H.getOxyLoss() >= (heal_threshold + 15))))
		for(var/datum/reagent/R in reagent_glass.reagents.reagent_list)
			if(!H.reagents.has_reagent(R))
				return 1
			continue

	if((H.getBruteLoss() >= heal_threshold) && (!H.reagents.has_reagent(treatment_brute)))
		return treatment_brute //If they're already medicated don't bother!

	if((H.getOxyLoss() >= (15 + heal_threshold)) && (!H.reagents.has_reagent(treatment_oxy)))
		return treatment_oxy

	if((H.getFireLoss() >= heal_threshold) && (!H.reagents.has_reagent(treatment_fire)))
		return treatment_fire

	if((H.getToxLoss() >= heal_threshold) && (!H.reagents.has_reagent(treatment_tox)))
		return treatment_tox

/* Construction */

/obj/item/weapon/storage/firstaid/attackby(var/obj/item/robot_parts/S, mob/user as mob)
	if ((!istype(S, /obj/item/robot_parts/l_arm)) && (!istype(S, /obj/item/robot_parts/r_arm)))
		..()
		return

	if(contents.len >= 1)
		user << "<span class='notice'>You need to empty [src] out first.</span>"
		return

	var/obj/item/weapon/firstaid_arm_assembly/A = new /obj/item/weapon/firstaid_arm_assembly
	if(istype(src, /obj/item/weapon/storage/firstaid/fire))
		A.skin = "ointment"
	else if(istype(src, /obj/item/weapon/storage/firstaid/toxin))
		A.skin = "tox"
	else if(istype(src, /obj/item/weapon/storage/firstaid/o2))
		A.skin = "o2"

	qdel(S)
	user.put_in_hands(A)
	user << "<span class='notice'>You add the robot arm to the first aid kit.</span>"
	user.drop_from_inventory(src)
	qdel(src)

/obj/item/weapon/storage/firstaid/attackby(var/obj/item/organ/external/S, mob/user as mob)
	if (!istype(S, /obj/item/organ/external/arm) || S.robotic != ORGAN_ROBOT)
		..()
		return

	if(contents.len >= 1)
		user << "<span class='notice'>You need to empty [src] out first.</span>"
		return

	var/obj/item/weapon/firstaid_arm_assembly/A = new /obj/item/weapon/firstaid_arm_assembly
	if(istype(src, /obj/item/weapon/storage/firstaid/fire))
		A.skin = "ointment"
	else if(istype(src, /obj/item/weapon/storage/firstaid/toxin))
		A.skin = "tox"
	else if(istype(src, /obj/item/weapon/storage/firstaid/o2))
		A.skin = "o2"

	qdel(S)
	user.put_in_hands(A)
	user << "<span class='notice'>You add the robot arm to the first aid kit.</span>"
	user.drop_from_inventory(src)
	qdel(src)

/obj/item/weapon/firstaid_arm_assembly
	name = "first aid/robot arm assembly"
	desc = "A first aid kit with a robot arm permanently grafted to it."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "firstaid_arm"
	var/build_step = 0
	var/created_name = "Medibot" //To preserve the name if it's a unique medbot I guess
	var/skin = null //Same as medbot, set to tox or ointment for the respective kits.
	w_class = ITEMSIZE_NORMAL

/obj/item/weapon/firstaid_arm_assembly/New()
	..()
	spawn(5) // Terrible. TODO: fix
		if(skin)
			overlays += image('icons/obj/aibots.dmi', "kit_skin_[src.skin]")

/obj/item/weapon/firstaid_arm_assembly/attackby(obj/item/weapon/W as obj, mob/user as mob)
	..()
	if(istype(W, /obj/item/weapon/pen))
		var/t = sanitizeSafe(input(user, "Enter new robot name", name, created_name), MAX_NAME_LEN)
		if(!t)
			return
		if(!in_range(src, usr) && loc != usr)
			return
		created_name = t
	else
		switch(build_step)
			if(0)
				if(istype(W, /obj/item/device/healthanalyzer))
					user.drop_item()
					qdel(W)
					build_step++
					user << "<span class='notice'>You add the health sensor to [src].</span>"
					name = "First aid/robot arm/health analyzer assembly"
					overlays += image('icons/obj/aibots.dmi', "na_scanner")

			if(1)
				if(isprox(W))
					user.drop_item()
					qdel(W)
					user << "<span class='notice'>You complete the Medibot! Beep boop.</span>"
					var/turf/T = get_turf(src)
					var/mob/living/bot/medbot/S = new /mob/living/bot/medbot(T)
					S.skin = skin
					S.name = created_name
					user.drop_from_inventory(src)
					qdel(src)

/**
 *  Receive payment with cashmoney.
 *
 *  usr is the mob who gets the change.
 */
/mob/living/bot/medbot/proc/pay_with_cash(var/obj/item/weapon/spacecash/cashmoney, mob/user)
	if(paying_time > cashmoney.worth)

		// This is not a status display message, since it's something the character
		// themselves is meant to see BEFORE putting the money in
		to_chat(usr, "\icon[cashmoney] <span class='warning'>That is not enough money.</span>")
		return 0

	if(istype(cashmoney, /obj/item/weapon/spacecash))

		visible_message("<span class='info'>\The [usr] inserts some cash into \the [src].</span>")
		cashmoney.worth -= paying_time

		if(cashmoney.worth <= 0)
			usr.drop_from_inventory(cashmoney)
			qdel(cashmoney)
		else
			cashmoney.update_icon()
	credit_purchase("(cash)")
	return 1

/mob/living/bot/medbot/proc/credit_purchase(var/target as text)
	department_accounts["Public Healthcare"].money += paying_time
	var/datum/transaction/T = new()
	T.target_name = target
	T.purpose = "Purchase of medibot usage time, [paying_time] seconds"
	T.amount = "[paying_time]"
	T.source_terminal = name
	T.date = current_date_string
	T.time = stationtime2text()
	vendor_account.transaction_log.Add(T)

/mob/living/bot/medbot/turn_on()
	..()
	timing = 1
	countdown()

/mob/living/bot/medbot/proc/countdown()
	if(timing && paid_time > 0)
		paid_time--
		sleep(10)
		New(countdown())
	else if(timing && paid_time <= 0)
		timing = 0
		paid_time = 0
		turn_off()

/mob/living/bot/medbot/turn_off()
	say(pick("I'm sorry! You're out of time!", "Please insert thalers to continue."))
	.. ()

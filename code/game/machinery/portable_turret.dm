/*
		Portable Turrets:

		Constructed from metal, a gun of choice, and a prox sensor.
		Gun can be a taser or laser or energy gun.

		This code is slightly more documented than normal, as requested by XSI on IRC.

*/

#define TURRET_PRIORITY_TARGET 2
#define TURRET_SECONDARY_TARGET 1
#define TURRET_NOT_TARGET 0

/obj/machinery/porta_turret
	name = "turret"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "turretCover"
	anchored = 1

	density = 0
	use_power = 1				//this turret uses and requires power
	idle_power_usage = 50		//when inactive, this turret takes up constant 50 Equipment power
	active_power_usage = 300	//when active, this turret takes up constant 300 Equipment power
	power_channel = EQUIP	//drains power from the EQUIPMENT channel

	var/raised = 0			//if the turret cover is "open" and the turret is raised
	var/raising= 0			//if the turret is currently opening or closing its cover
	var/health = 80			//the turret's health
	var/maxhealth = 80		//turrets maximal health.
	var/auto_repair = 0		//if 1 the turret slowly repairs itself.
	var/locked = 1			//if the turret's behaviour control access is locked
	var/controllock = 0		//if the turret responds to control panels

	var/installation = /obj/item/weapon/gun/energy/gun		//the type of weapon installed
	var/gun_charge = 0		//the charge of the gun inserted
	var/projectile = null	//holder for bullettype
	var/eprojectile = null	//holder for the shot when emagged
	var/reqpower = 400		//holder for power needed
	var/iconholder = null	//holder for the icon_state. 1 for orange sprite, null for blue.
	var/obj/item/weapon/gun/energy/t_gun = null	//turret gun holder

	var/last_fired = 0		//1: if the turret is cooling down from a shot, 0: turret is ready to fire
	var/shot_delay = 20		//2 seconds between each shot

	var/check_arrest = 1	//checks if the perp is set to arrest
	var/check_records = 1	//checks if a security record exists at all
	var/check_weapons = 0	//checks if it can shoot people that have a weapon they aren't authorized to have
	var/check_access = 1	//if this is active, the turret shoots everything that does not meet the access requirements
	var/check_anomalies = 1	//checks if it can shoot at unidentified lifeforms (ie xenos)
	var/check_n_synth = 0 	//if active, will shoot at anything not an AI or cyborg
	var/shot_synth = 0	//if active and in letal, will shoot any cyborgs
	var/ailock = 0 			// AI cannot use this
	var/special_control = 0 //AI (and only AI) can set shot_synth

	var/attacked = 0		//if set to 1, the turret gets pissed off and shoots at people nearby (unless they have sec access!)

	var/enabled = 1				//determines if the turret is on
	var/lethal = 0			//whether in lethal or stun mode

	var/shot_sound 			//what sound should play when the turret fires
	var/eshot_sound			//what sound should play when the emagged turret fires

	var/datum/effect/effect/system/spark_spread/spark_system	//the spark system, used for generating... sparks?

	var/wrenching = 0
	var/last_target			//last target fired at, prevents turrets from erratically firing at all valid targets in range

/obj/machinery/porta_turret/station_default
	check_n_synth = 1

/obj/machinery/porta_turret/crescent
	ailock = 1
	check_access = 1
	check_arrest = 1
	check_records = 1
	check_weapons = 1
	check_anomalies = 1

/obj/machinery/porta_turret/stationary
	ailock = 1
	lethal = 1
	installation = /obj/item/weapon/gun/energy/laser

/obj/machinery/porta_turret/AI_special
	special_control = 1

/obj/machinery/porta_turret/New()
	..()
	req_one_access = list(access_security, access_heads)

	//Sets up a spark system
	spark_system = new /datum/effect/effect/system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

	setup()

/obj/machinery/porta_turret/crescent/New()
	..()
	req_one_access.Cut()
	req_access = list(access_cent_specops)

/obj/machinery/porta_turret/Destroy()
	qdel(spark_system)
	spark_system = null
	installation = null
	qdel(t_gun)
	t_gun = null
	return ..()

/obj/machinery/porta_turret/proc/setup()
	qdel(t_gun)
	t_gun = new installation(src)	//All energy-based weapons are applicable
	var/list/t_gun_ammo = t_gun.ammo_type
	var/obj/item/ammo_casing/energy/t_gun_ammo_casing = t_gun_ammo[1]
	projectile = t_gun_ammo_casing.BB.type
	if(t_gun_ammo.len > 1)
		t_gun_ammo_casing = t_gun_ammo[2]
		eprojectile = t_gun_ammo_casing.BB.type
	else
		eprojectile = projectile
	shot_sound = t_gun.fire_sound
	eshot_sound = shot_sound

	switch(installation)
		if(/obj/item/weapon/gun/energy/laser/bluetag)
			eprojectile = /obj/item/projectile/beam/lastertag/omni //This bolt will stun ERRYONE with a vest
			reqpower = 100
			req_one_access.Cut()
			req_access = list(access_maint_tunnels)
			shot_delay = 30

		if(/obj/item/weapon/gun/energy/laser/redtag)
			eprojectile = /obj/item/projectile/beam/lastertag/omni
			reqpower = 100
			req_one_access.Cut()
			req_access = list(access_maint_tunnels)
			shot_delay = 30

		if(/obj/item/weapon/gun/energy/laser/practice)
			iconholder = 1
			eprojectile = /obj/item/projectile/beam
			reqpower = 300

		if(/obj/item/weapon/gun/energy/pulse_rifle)
			iconholder = 1
			reqpower = 700

		if(/obj/item/weapon/gun/energy/ionrifle)
			iconholder = 1
			reqpower = 700

		if(/obj/item/weapon/gun/energy/laser/retro)
			iconholder = 1

		if(/obj/item/weapon/gun/energy/laser/captain)
			iconholder = 1

		if(/obj/item/weapon/gun/energy/lasercannon)
			reqpower = 600
			iconholder = 1

		if(/obj/item/weapon/gun/energy/crossbow)
			reqpower = 75
			iconholder = 1

		if(/obj/item/weapon/gun/energy/taser)
			reqpower = 200

		if(/obj/item/weapon/gun/energy/stunrevolver)
			reqpower = 200

		if(/obj/item/weapon/gun/energy/gun)
			eshot_sound = 'sound/weapons/Laser.ogg'

		if(/obj/item/weapon/gun/energy/gun/nuclear)
			eshot_sound = 'sound/weapons/Laser.ogg'

var/list/turret_icons

/obj/machinery/porta_turret/update_icon()
	if(!turret_icons)
		turret_icons = list()
		turret_icons["open"] = image(icon, "openTurretCover")

	underlays.Cut()
	underlays += turret_icons["open"]

	if(stat & BROKEN)
		icon_state = "destroyed_target_prism"
	else if(raised || raising)
		if(powered() && enabled)
			if(iconholder)
				//lasers have a orange icon
				icon_state = "orange_target_prism"
			else
				//almost everything has a blue icon
				icon_state = "target_prism"
		else
			icon_state = "grey_target_prism"
	else
		icon_state = "turretCover"

/obj/machinery/porta_turret/proc/isLocked(mob/user)
	if(ailock && issilicon(user))
		to_chat(user, "<span class='notice'>There seems to be a firewall preventing you from accessing this device.</span>")
		return 1

	if(locked && !issilicon(user))
		to_chat(user, "<span class='notice'>Access denied.</span>")
		return 1

	return 0

/obj/machinery/porta_turret/attack_ai(mob/user)
	if(isLocked(user))
		return

	interact(user)

/obj/machinery/porta_turret/attack_hand(mob/user)
	if(isLocked(user))
		return

	interact(user)

/obj/machinery/porta_turret/interact(mob/user)
	user.set_machine(src)

	var/dat = text({"
<table width="100%" cellspacing="0" cellpadding="4">
	<tr>
		<td>Status: </td><td>[]</td>
	</tr>
	<tr></tr>
	<tr>
		<td>Lethal Mode: </td><td>[]</td>
	</tr>
	<tr>
		<td>Neutralize All Non-Synthetics: </td><td>[]</td>
	</tr>
	<tr>
		<td>Neutralize All Cyborgs: </td><td>[]</td>
	</tr>
	<tr>
		<td>Check Weapon Authorization: </td><td>[]</td>
	</tr>
	<tr>
		<td>Check Security Records: </td><td>[]</td>
	</tr>
	<tr>
		<td>Check Arrest Status: </td><td>[]</td>
	</tr>
	<tr>
		<td>Check Access Authorization: </td><td>[]</td>
	</tr>
	<tr>
		<td>Check misc. Lifeforms: </td><td>[]</td>
	</tr>
</table>"},

"<A href='?src=\ref[src];command=enable'>[enabled ? "On" : "Off"]</A>",
"<A href='?src=\ref[src];command=lethal'>[lethal ? "On" : "Off"]</A>",
"<A href='?src=\ref[src];command=check_n_synth'>[check_n_synth ? "Yes" : "No"]</A>",
"[(special_control && isAI(user)) ? "<A href='?src=\ref[src];command=shot_synth'>[shot_synth ? "Yes" : "No"]</A>" : "NOT ALLOWED"]",
"<A href='?src=\ref[src];command=check_weapons'>[check_weapons ? "Yes" : "No"]</A>",
"<A href='?src=\ref[src];command=check_records'>[check_records ? "Yes" : "No"]</A>",
"<A href='?src=\ref[src];command=check_arrest'>[check_arrest ? "Yes" : "No"]</A>",
"<A href='?src=\ref[src];command=check_access'>[check_access ? "Yes" : "No"]</A>",
"<A href='?src=\ref[src];command=check_anomalies'>[check_anomalies ? "Yes" : "No"]</A>")

	var/datum/browser/popup = new(user, "window=autosec", "Automatic Portable Turret Installation", 400, 320)
	popup.set_content(dat)
	popup.open()

/obj/machinery/porta_turret/proc/HasController()
	var/area/A = get_area(src)
	return A && A.turret_controls.len > 0

/obj/machinery/porta_turret/is_operational_topic()
	return !((stat & (NOPOWER|BROKEN)) || HasController()) && anchored

/obj/machinery/porta_turret/Topic(href, href_list)
	. = ..()
	if(!.)
		return

	if(href_list["command"])
		switch(href_list["command"])
			if("enable")
				enabled = !enabled
			if("lethal")
				lethal = !lethal
			if("check_n_synth")
				check_n_synth = !check_n_synth
			if("shot_synth")
				shot_synth = !shot_synth
			if("check_weapons")
				check_weapons = !check_weapons
			if("check_records")
				check_records = !check_records
			if("check_arrest")
				check_arrest = !check_arrest
			if("check_access")
				check_access = !check_access
			if("check_anomalies")
				check_anomalies = !check_anomalies

	updateUsrDialog()

/obj/machinery/porta_turret/power_change()
	if(powered())
		stat &= ~NOPOWER
		update_icon()
	else
		spawn(rand(0, 15))
			stat |= NOPOWER
			update_icon()


/obj/machinery/porta_turret/attackby(obj/item/I, mob/user)
	if(stat & BROKEN)
		if(istype(I, /obj/item/weapon/crowbar))
			//If the turret is destroyed, you can remove it with a crowbar to
			//try and salvage its components
			to_chat(user, "<span class='notice'>You begin prying the metal coverings off.</span>")
			if(do_after(user, 20, src))
				if(prob(70))
					to_chat(user, "<span class='notice'>You remove the turret and salvage some components.</span>")
					if(t_gun)
						t_gun.loc = src.loc
						t_gun.power_supply.charge = gun_charge
						t_gun.update_icon()
						t_gun = null
					if(prob(50))
						new /obj/item/stack/sheet/metal(loc, rand(1,4))
					if(prob(50))
						new /obj/item/device/assembly/prox_sensor(loc)
				else
					to_chat(user, "<span class='notice'>You remove the turret but did not manage to salvage anything.</span>")
				qdel(src) // qdel

	else if((istype(I, /obj/item/weapon/wrench)))
		if(enabled || raised)
			to_chat(user, "<span class='warning'>You cannot unsecure an active turret!</span>")
			return
		if(wrenching)
			to_chat(user, "<span class='warning'>Someone is already [anchored ? "un" : ""]securing the turret!</span>")
			return
		if(!anchored && isinspace())
			to_chat(user, "<span class='warning'>Cannot secure turrets in space!</span>")
			return

		user.visible_message( \
				"<span class='warning'>[user] begins [anchored ? "un" : ""]securing the turret.</span>", \
				"<span class='notice'>You begin [anchored ? "un" : ""]securing the turret.</span>" \
			)

		wrenching = 1
		if(do_after(user, 50, src))
			//This code handles moving the turret around. After all, it's a portable turret!
			if(!anchored)
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				anchored = 1
				update_icon()
				to_chat(user, "<span class='notice'>You secure the exterior bolts on the turret.</span>")
			else
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				anchored = 0
				to_chat(user, "<span class='notice'>You unsecure the exterior bolts on the turret.</span>")
				update_icon()
		wrenching = 0

	else if(istype(I, /obj/item/weapon/card/id) || istype(I, /obj/item/device/pda))
		//Behavior lock/unlock mangement
		if(allowed(user))
			locked = !locked
			to_chat(user, "<span class='notice'>Controls are now [locked ? "locked" : "unlocked"].</span>")
			updateUsrDialog()
		else
			to_chat(user, "<span class='notice'>Access denied.</span>")

	else if (istype(I, /obj/item/weapon/card/emag) && !emagged)
		//Emagging the turret makes it go bonkers and stun everyone. It also makes
		//the turret shoot much, much faster.
		to_chat(user, "<span class='warning'>You short out [src]'s threat assessment circuits.</span>")
		visible_message("[src] hums oddly...")
		emagged = 1
		iconholder = 1
		controllock = 1
		enabled = 0 //turns off the turret temporarily
		spawn(80) //8 seconds for the traitor to gtfo of the area before the turret decides to ruin his shit
			enabled = 1 //turns it back on. The cover popUp() popDown() are automatically called in process(), no need to define it here

	else
		//if the turret was attacked with the intention of harming it:
		take_damage(I.force * 0.5)
		if((I.force * 0.5) > 1) //if the force of impact dealt at least 1 damage, the turret gets pissed off
			if(!attacked && !emagged)
				attacked = 1
				spawn(60)
					attacked = 0
		..()

/obj/machinery/porta_turret/proc/take_damage(force)
	if(!raised && !raising)
		force = force / 8
		if(force < 5)
			return

	health -= force
	if (force > 5 && prob(45))
		spark_system.start()
	if(health <= 0)
		die() //the death process :(

/obj/machinery/porta_turret/bullet_act(obj/item/projectile/Proj)
	var/damage = Proj.damage

	if(!damage)
		return

	if(enabled)
		if(!attacked && !emagged)
			attacked = 1
			spawn(60)
				attacked = 0

	..()

	take_damage(damage)

/obj/machinery/porta_turret/emp_act(severity)
	if(enabled)
		//if the turret is on, the EMP no matter how severe disables the turret for a while
		//and scrambles its settings, with a slight chance of having an emag effect
		check_arrest = prob(50)
		check_records = prob(50)
		check_weapons = prob(50)
		check_access = prob(20)	// check_access is a pretty big deal, so it's least likely to get turned on
		check_anomalies = prob(50)
		shot_synth = prob(20)
		if(prob(5))
			emagged = 1

		enabled = 0
		spawn(rand(60,600))
			enabled = 1

	..()

/obj/machinery/porta_turret/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			if(prob(25))
				qdel(src)
			else
				take_damage(initial(health) * 8) //should instakill most turrets
		if(3)
			take_damage(initial(health) * 8 * 0.33) // 8/3 ~ 8*0.33

/obj/machinery/porta_turret/proc/die()	//called when the turret dies, ie, health <= 0
	health = 0
	stat |= BROKEN	//enables the BROKEN bit
	spark_system.start()	//creates some sparks because they look cool
	update_icon()

/obj/machinery/porta_turret/process()
	//the main machinery process

	if(stat & (NOPOWER|BROKEN))
		//if the turret has no power or is broken, make the turret pop down if it hasn't already
		popDown()
		return

	if(!enabled)
		//if the turret is off, make it pop down
		popDown()
		return

	var/list/targets = list()			//list of primary targets
	var/list/secondarytargets = list()	//targets that are least important

	for(var/mob/M in mobs_in_view(world.view, src))
		assess_and_assign(M, targets, secondarytargets)

	if(!tryToShootAt(targets))
		if(!tryToShootAt(secondarytargets)) // if no valid targets, go for secondary targets
			spawn()
				popDown() // no valid targets, close the cover

	if(auto_repair && (health < maxhealth))
		use_power(20000)
		health = min(health+1, maxhealth) // 1HP for 20kJ

/obj/machinery/porta_turret/proc/assess_and_assign(mob/living/L, list/targets, list/secondarytargets)
	switch(assess_living(L))
		if(TURRET_PRIORITY_TARGET)
			targets += L
		if(TURRET_SECONDARY_TARGET)
			secondarytargets += L

/obj/machinery/porta_turret/proc/assess_living(mob/living/L)
	if(!istype(L))
		return TURRET_NOT_TARGET

	if(L.invisibility >= INVISIBILITY_LEVEL_ONE) // Cannot see him. see_invisible is a mob-var
		return TURRET_NOT_TARGET

	if(!L)
		return TURRET_NOT_TARGET

	if(get_dist(src, L) > 7)	//if it's too far away, why bother?
		return TURRET_NOT_TARGET

	if(!check_trajectory(L, src))	//check if we have true line of sight
		return TURRET_NOT_TARGET

	if(lethal && (locate(/mob/living/silicon/ai) in get_turf(L)))		//don't accidentally kill the AI!
		return TURRET_NOT_TARGET

	if(L.stat)		//if the perp is dead/dying...
		if(!emagged)
			return TURRET_NOT_TARGET	//no need to bother really, move onto next potential victim!
		else
			return TURRET_SECONDARY_TARGET	//and turret emagged - kill them

	if(emagged)		// If emagged - kill all
		return TURRET_PRIORITY_TARGET

	if(isrobot(L)) //If the target is robot and we want to shoot robots
		if(lethal && shot_synth)
			return TURRET_PRIORITY_TARGET
		else
			return TURRET_NOT_TARGET

	if(check_n_synth)	//If it's set to attack all non-silicons, target them!
		if(L.lying && !L.crawling)
			return lethal ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET
		return TURRET_PRIORITY_TARGET

	if(L.restrained()) // If the target is handcuffed, leave it alone
		return TURRET_NOT_TARGET

	if(isanimal(L)) // Animals are not so dangerous
		return check_anomalies ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET

	if(isalien(L)) // Xenos are dangerous
		return check_anomalies ? TURRET_PRIORITY_TARGET	: TURRET_NOT_TARGET

	if(ishuman(L))	//if the target is a human, analyze threat level
		if(assess_perp(L) < 4)
			return TURRET_NOT_TARGET	//if threat level < 4, keep going

	if(L.lying && !L.crawling)		//if the perp is lying down, it's still a target but a less-important target
		return lethal ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET

	return TURRET_PRIORITY_TARGET	//if the perp has passed all previous tests, congrats, it is now a "shoot-me!" nominee

/obj/machinery/porta_turret/proc/assess_perp(mob/living/carbon/human/H)
	if(!H || !istype(H))
		return 0

	if(emagged)
		return 10

	return H.assess_perp(src, check_access, check_weapons, check_records, check_arrest)

/obj/machinery/porta_turret/proc/tryToShootAt(list/mob/living/targets)
	if(targets.len && last_target && (last_target in targets) && target(last_target))
		return 1

	while(targets.len > 0)
		var/mob/living/M = pick(targets)
		targets -= M
		if(target(M))
			return 1


/obj/machinery/porta_turret/proc/popUp()	//pops the turret up
	if(raising || raised)
		return
	if(stat & BROKEN)
		return
	set_raised_raising(raised, 1)
	update_icon()

	var/atom/flick_holder = PoolOrNew(/obj/effect/porta_turret_cover, loc)
	flick_holder.layer = layer + 0.1
	flick("popup", flick_holder)
	spawn(10)
		qdel(flick_holder)

	set_raised_raising(1, 0)
	update_icon()

/obj/machinery/porta_turret/proc/popDown()	//pops the turret down
	last_target = null
	if(raising || !raised)
		return
	if(stat & BROKEN)
		return
	set_raised_raising(raised, 1)
	update_icon()

	var/atom/flick_holder = PoolOrNew(/obj/effect/porta_turret_cover, loc)
	flick_holder.layer = layer + 0.1
	flick("popdown", flick_holder)
	spawn(10)
		qdel(flick_holder)

	set_raised_raising(0, 0)
	update_icon()

/obj/machinery/porta_turret/proc/set_raised_raising(raised, raising)
	src.raised = raised
	src.raising = raising
	density = raised || raising

/obj/machinery/porta_turret/proc/target(mob/living/target)
	if(target)
		last_target = target
		spawn()
			popUp()				//pop the turret up if it's not already up.
		set_dir(get_dir(src, target))	//even if you can't shoot, follow the target
		spawn()
			shootAt(target)
		return 1
	return

/obj/machinery/porta_turret/proc/shootAt(mob/living/target)
	//any emagged turrets will shoot extremely fast! This not only is deadly, but drains a lot power!
	if(!(emagged || attacked))		//if it hasn't been emagged or attacked, it has to obey a cooldown rate
		if(last_fired || !raised)	//prevents rapid-fire shooting, unless it's been emagged
			return
		last_fired = 1
		spawn(shot_delay)
			last_fired = 0

	var/turf/T = get_turf(src)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return

	if(!raised) //the turret has to be raised in order to fire - makes sense, right?
		return

	if(!eprojectile || !projectile)
		return

	update_icon()
	var/obj/item/projectile/A
	if(emagged || lethal)
		A = new eprojectile(loc)
	else
		A = new projectile(loc)

	// Lethal/emagged turrets use twice the power due to higher energy beams
	// Emagged turrets again use twice as much power due to higher firing rates
	use_power(reqpower * (2 * (emagged || lethal)) * (2 * emagged))

	A.original = target
	A.current = T
	A.starting = T
	A.yo = U.y - T.y
	A.xo = U.x - T.x
	spawn(0)
		A.process()

	if(emagged || lethal)
		playsound(loc, eshot_sound, 75, 1)
	else
		playsound(loc, shot_sound, 75, 1)


/obj/machinery/porta_turret/attack_animal(mob/living/simple_animal/M)
	M.do_attack_animation(src)
	if(M.melee_damage_upper == 0)
		return
	if(!(stat & BROKEN))
		visible_message("<span class='danger'>[M] [M.attacktext] [src]!</span>")
		M.attack_log += text("\[[time_stamp()]\] <font color='red'>attacked [src.name]</font>")
		take_damage(M.melee_damage_upper)
	else

		to_chat(M, "<span class='red'>That object is useless to you.</span>")
	return


/obj/machinery/porta_turret/attack_alien(mob/living/carbon/alien/humanoid/M)
	M.do_attack_animation(src)
	if(!(stat & BROKEN))
		playsound(src.loc, 'sound/weapons/slash.ogg', 25, 1, -1)
		visible_message("<span class='danger'>[M] has slashed at [src]!</span>")
		M.attack_log += text("\[[time_stamp()]\] <font color='red'>attacked [src.name]</font>")
		take_damage(15)
	else
		to_chat(M, "<span class='alien'>That object is useless to you.</span>")
	return


/datum/turret_checks
	var/enabled
	var/lethal
	var/check_n_synth
	var/check_access
	var/check_records
	var/check_arrest
	var/check_weapons
	var/check_anomalies
	var/shot_synth
	var/ailock

/obj/machinery/porta_turret/proc/setState(datum/turret_checks/TC)
	if(controllock)
		return
	src.enabled = TC.enabled
	src.lethal = TC.lethal
	src.iconholder = TC.lethal

	check_n_synth = TC.check_n_synth
	check_access = TC.check_access
	check_records = TC.check_records
	check_arrest = TC.check_arrest
	check_weapons = TC.check_weapons
	check_anomalies = TC.check_anomalies
	shot_synth = TC.shot_synth
	ailock = TC.ailock

	src.power_change()

/*
		Portable turret constructions
		Known as "turret frame"s
*/

/obj/machinery/porta_turret_construct
	name = "turret frame"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "turret_frame"
	density = 1
	var/build_step = 0			//the current step in the building process
	var/finish_name="turret"	//the name applied to the product turret
	var/installation = null		//the gun type installed
	var/gun_charge = 0			//the gun charge of the gun type installed


/obj/machinery/porta_turret_construct/attackby(obj/item/I, mob/user)
	//this is a bit unwieldy but self-explanatory
	switch(build_step)
		if(0)	//first step
			if(istype(I, /obj/item/weapon/wrench) && !anchored)
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				to_chat(user, "<span class='notice'>You secure the external bolts.</span>")
				anchored = 1
				build_step = 1
				return

			else if(istype(I, /obj/item/weapon/crowbar) && !anchored)
				playsound(loc, 'sound/items/Crowbar.ogg', 75, 1)
				to_chat(user, "<span class='notice'>You dismantle the turret construction.</span>")
				new /obj/item/stack/sheet/metal( loc, 5)
				qdel(src)
				return

		if(1)
			if(istype(I, /obj/item/stack/sheet/metal))
				var/obj/item/stack/sheet/metal/M = I
				if(M.amount >= 2)
					M.use(2)
					to_chat(user, "<span class='notice'>You add some metal armor to the interior frame.</span>")
					build_step = 2
					icon_state = "turret_frame2"
				else
					to_chat(user, "<span class='warning'>You need two sheets of metal to continue construction.</span>")
				return

			else if(istype(I, /obj/item/weapon/wrench))
				playsound(loc, 'sound/items/Ratchet.ogg', 75, 1)
				to_chat(user, "<span class='notice'>You unfasten the external bolts.</span>")
				anchored = 0
				build_step = 0
				return


		if(2)
			if(istype(I, /obj/item/weapon/wrench))
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				to_chat(user, "<span class='notice'>You bolt the metal armor into place.</span>")
				build_step = 3
				return

			else if(istype(I, /obj/item/weapon/weldingtool))
				var/obj/item/weapon/weldingtool/WT = I
				if(!WT.isOn())
					return
				if(WT.get_fuel() < 5) //uses up 5 fuel.
					to_chat(user, "<span class='notice'>You need more fuel to complete this task.</span>")
					return

				playsound(loc, pick('sound/items/Welder.ogg', 'sound/items/Welder2.ogg'), 50, 1)
				if(do_after(user, 20, src))
					if(!src || !WT.remove_fuel(5, user)) return
					build_step = 1
					to_chat(user, "You remove the turret's interior metal armor.")
					new /obj/item/stack/sheet/metal(loc, 2)
					return


		if(3)
			if(istype(I, /obj/item/weapon/gun/energy)) //the gun installation part
				if(isrobot(user))
					return
				var/obj/item/weapon/gun/energy/E = I //typecasts the item to an energy gun
				if(!user.unEquip(I))
					to_chat(user, "<span class='notice'>\the [I] is stuck to your hand, you cannot put it in \the [src]</span>")
					return
				installation = I.type //installation becomes I.type
				gun_charge = E.power_supply.charge //the gun's charge is stored in gun_charge
				to_chat(user, "<span class='notice'>You add [I] to the turret.</span>")
				build_step = 4
				qdel(I) //delete the gun :(
				return

			else if(istype(I, /obj/item/weapon/wrench))
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				to_chat(user, "<span class='notice'>You remove the turret's metal armor bolts.</span>")
				build_step = 2
				return

		if(4)
			if(isprox(I))
				build_step = 5
				if(!user.unEquip(I))
					to_chat(user, "<span class='notice'>\the [I] is stuck to your hand, you cannot put it in \the [src]</span>")
					return
				to_chat(user, "<span class='notice'>You add the prox sensor to the turret.</span>")
				qdel(I)
				return

			//attack_hand() removes the gun

		if(5)
			if(istype(I, /obj/item/weapon/screwdriver))
				playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
				build_step = 6
				to_chat(user, "<span class='notice'>You close the internal access hatch.</span>")
				return

			//attack_hand() removes the prox sensor

		if(6)
			if(istype(I, /obj/item/stack/sheet/metal))
				var/obj/item/stack/sheet/metal/M = I
				if(M.amount >= 2)
					M.use(2)
					to_chat(user, "<span class='notice'>You add some metal armor to the exterior frame.</span>")
					build_step = 7
				else
					to_chat(user, "<span class='warning'>You need two sheets of metal to continue construction.</span>")
				return

			else if(istype(I, /obj/item/weapon/screwdriver))
				playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
				build_step = 5
				to_chat(user, "<span class='notice'>You open the internal access hatch.</span>")
				return

		if(7)
			if(istype(I, /obj/item/weapon/weldingtool))
				var/obj/item/weapon/weldingtool/WT = I
				if(!WT.isOn()) return
				if(WT.get_fuel() < 5)
					to_chat(user, "<span class='notice'>You need more fuel to complete this task.</span>")

				playsound(loc, pick('sound/items/Welder.ogg', 'sound/items/Welder2.ogg'), 50, 1)
				if(do_after(user, 30, src))
					if(!src || !WT.remove_fuel(5, user))
						return
					build_step = 8
					to_chat(user, "<span class='notice'>You weld the turret's armor down.</span>")

					//The final step: create a full turret
					var/obj/machinery/porta_turret/Turret = new (loc)
					Turret.name = finish_name
					Turret.installation = installation
					Turret.gun_charge = gun_charge
					Turret.enabled = 0
					Turret.setup()

					qdel(src) // qdel

			else if(istype(I, /obj/item/weapon/crowbar))
				playsound(loc, 'sound/items/Crowbar.ogg', 75, 1)
				to_chat(user, "<span class='notice'>You pry off the turret's exterior armor.</span>")
				new /obj/item/stack/sheet/metal(loc, 2)
				build_step = 6
				return

	if(istype(I, /obj/item/weapon/pen))	//you can rename turrets like bots!
		var/t = input(user, "Enter new turret name", name, finish_name)
		if(!t)
			return
		if(!in_range(src, usr) && loc != usr)
			return

		t = sanitize(copytext(t,1,MAX_NAME_LEN))
		finish_name = t
		return

	..()


/obj/machinery/porta_turret_construct/attack_hand(mob/user)
	switch(build_step)
		if(4)
			if(!installation)
				return
			build_step = 3
			var/obj/item/weapon/gun/energy/Gun = new installation(loc)
			Gun.power_supply.charge = gun_charge
			Gun.update_icon()
			installation = null
			gun_charge = 0
			to_chat(user, "<span class='notice'>You remove [Gun] from the turret frame.</span>")

		if(5)
			to_chat(user, "<span class='notice'>You remove the prox sensor from the turret frame.</span>")
			new /obj/item/device/assembly/prox_sensor(loc)
			build_step = 4

/obj/machinery/porta_turret_construct/attack_ai()
	return

/obj/effect/porta_turret_cover
	icon = 'icons/obj/turrets.dmi'

/obj/effect/porta_turret_cover/Destroy()
	return QDEL_HINT_PUTINPOOL

#undef TURRET_PRIORITY_TARGET
#undef TURRET_SECONDARY_TARGET
#undef TURRET_NOT_TARGET

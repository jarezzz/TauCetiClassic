/obj/item/weapon/melee/powerfist
	name = "power-fist"
	desc = "A metal gauntlet with a piston-powered ram ontop for that extra 'ompfh' in your punch."
	icon_state = "powerfist"
	item_state = "powerfist"
	flags = CONDUCT
	attack_verb = list("whacked", "fisted", "power-punched")
	force = 20
	throwforce = 10
	throw_range = 7
	w_class = 3
	origin_tech = "combat=5;powerstorage=3;syndicate=3"
	var/fisto_setting = 1
	var/gasperfist = 3
	var/obj/item/weapon/tank/tank = null //Tank used for the gauntlet's piston-ram.


/obj/item/weapon/melee/powerfist/examine(mob/user)
	..()
	if(!in_range(user, src))
		to_chat(user,"<span class='notice'>You'll need to get closer to see any more.</span>")
		return
	if(tank)
		to_chat(user,"<span class='notice'>\icon [tank] It has \the [tank] mounted onto it.</span>")


/obj/item/weapon/melee/powerfist/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/weapon/tank))
		if(!tank)
			var/obj/item/weapon/tank/IT = W
			if(IT.volume <= 3)
				to_chat(user,"<span class='warning'>\The [IT] is too small for \the [src].</span>")
				return
			updateTank(W, 0, user)
		else
			updateTank(W, 1, user)
	else if(istype(W, /obj/item/weapon/wrench))
		switch(fisto_setting)
			if(1)
				fisto_setting = 2
			if(2)
				fisto_setting = 3
			if(3)
				fisto_setting = 1
		playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
		to_chat(user,"<span class='notice'>You tweak \the [src]'s piston valve to [fisto_setting].</span>")
	else if(istype(W, /obj/item/weapon/screwdriver))
		updateTank(tank, 1, user)


/obj/item/weapon/melee/powerfist/proc/updateTank(obj/item/weapon/tank/thetank, removing = 0, mob/living/carbon/human/user)
	if(removing)
		if(!tank)
			to_chat(user,"<span class='notice'>\The [src] currently has no tank attached to it.</span>")
			return
		to_chat(user,"<span class='notice'>You detach \the [thetank] from \the [src].</span>")
		tank.forceMove(get_turf(user))
		user.put_in_hands(tank)
		tank = null
	else
		if(tank)
			to_chat(user,"<span class='warning'>\The [src] already has a tank.</span>")
			return
		if(!user.unEquip(thetank))
			return
		to_chat(user,"<span class='notice'>You hook \the [thetank] up to \the [src].</span>")
		tank = thetank
		thetank.forceMove(src)


/obj/item/weapon/melee/powerfist/attack(mob/living/target, mob/living/user)
	if(!tank)
		to_chat(user,"<span class='warning'>\The [src] can't operate without a source of gas!</span>")
		return
	else if(!tank.air_contents.remove(gasperfist * fisto_setting))
		to_chat(user,"<span class='warning'>\The [src]'s piston-ram lets out a weak hiss, it needs more gas!</span>")
		playsound(loc, 'sound/effects/refill.ogg', 50, 1)
		return
	target.apply_damage(force * fisto_setting, BRUTE, user.zone_sel.selecting)
	target.visible_message("<span class='danger'>[user]'s powerfist lets out a loud hiss as they punch [target.name]!</span>", \
		"<span class='userdanger'>You cry out in pain as [user]'s punch flings you backwards!</span>")
	PoolOrNew(/obj/item/effect/kinetic_blast, target.loc)
	playsound(loc, 'sound/weapons/resonator_blast.ogg', 50, 1)
	playsound(loc, 'sound/weapons/genhit2.ogg', 50, 1)

	var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))
	spawn(1)
		target.throw_at(throw_target, 5 * fisto_setting, 0.2)

	target.attack_log += text("\[[time_stamp()]\]<font color='orange'> Has been powerfisted by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>powerfisted [target.name]'s ([target.ckey])</font>")
	msg_admin_attack("[user] ([user.ckey]) powerfisted [target.name] ([target.ckey]) <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[target.x];Y=[target.y];Z=[target.z]'>JMP</a>)</span></span>")
	return
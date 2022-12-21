![image](https://user-images.githubusercontent.com/70592880/208999774-f85d79c7-691b-4614-b438-3883fd2ab80d.png)
## Description
This is a Capture The Flag game mode for FiveM, with custom flag props and customizable rulesets. Two teams fight to capture the opponents flag, while their flag is still in base. 

## Basics
 - If your flag is taken, hunt down the flag carrier, and try to kill them and return your flag by touching it while it's dropped. This will return your flag back to your base.
 - If your teammate dies with the enemy flag, you can pickup the dropped flag.
 - You can only score a point by bringing the enemy flag back to your team's returned flag.
 - If you are carrying the flag, and exit the match area, the enemy flag will be returned to them.

## Commands
**initctf**

This command will initiate the CTF match, and designate this person as the admin of the match. 

**ctfmenu**

Once a ctf match is initiated and the match map has been chosen by the admin, players can:
 - Choose the team they would like to play for.
 - Remove from their chosen team.

Once the match has been created the admin can:
 - Choose the map the match is played on.
 - Start the match, given there are players.
 - End the match while the game is in progress.

## Included maps/courses
### Paleto Carnage
![image](https://user-images.githubusercontent.com/70592880/208991323-b862ceec-6c23-4fe9-854b-796f32904d06.png)

### Redwood Rampage
![image](https://user-images.githubusercontent.com/70592880/208991356-f06819d4-643f-4249-bccd-f4448da4c6dc.png)

## Customized Rulesets/Config
**allowVehicles** - Prevents players from entering vehicles if false.

**maxScore** - Sets the score limit to win the match.

**autoRespawn** - Automatically respawn at base on death

**respawnTime** - In seconds. delay before respawn, when you die, if autoRespawn

**restrictedCreation** - If true, restricts match creation to a list of user licenses.

**showZoneBorder** - This turns zones debug setting on. I could see why you want this on, but I personally things its stupid.

## Credit
- [Snipe](https://github.com/pushkart2) A big thanks to Snipe and his partner for creating the scoreboard included in this resource.

## Dependencies
- [ox_lib](https://github.com/overextended/ox_lib)
- [assets_ctfflags](https://github.com/JoeSzymkowiczFiveM/assets_ctfflags) - These are the models specified in the existing game config. I guess you could technically use any other model in FiveM, you would just need to specify them in the game config.
- qb-core/qbox/ESX - When autoRespawn is set to true, the script calls the revive event compatible with these frameworks. Compatibility can be expanded to other frameworks if someone wants to do a PR or send me the event names.

## Preview
[Kill opponent and return flag](https://streamable.com/lv8hgr)

[Steal the enemy flag](https://streamable.com/dzfvf1)

[Capture the flag and win](https://streamable.com/ms48lf)

[Init and CTF Menu](https://streamable.com/vonjif)

### TODO
- [ ] Better way of displaying course boundary
- [ ] Warmup
- [ ] Handling around disconnected players and rejoining the game
- [ ] Admin pausing the game
- [ ] More maps
- [ ] Powerups - temporary speed and health modifiers

# minecraft-server cookbook changelog

## Version 0.1.4 (1/12/2017)

- [John Harrison] - Update README.md
- [John Harrison] - Add better testing for the cookbook on different OSs
- [John Harrison] - Update bukkit_plugin to work with the updated Bukkit website
- [John Harrison] - Fix service status not working on Centos 6 and Ubuntu 14
- [John Harrison] - Can now add, change, and remove settings from config files
- [John Harrison] - minecraft_server will wait for the server to finish starting and stopping before continuing
- [John Harrison] - Remove delay property in minecraft_service
- [John Harrison] - Add support for SpigotMC's Bungeecord server
- [John Harrison] - Fix bug in action :update in bukkit_server and spigot_server
- [John Harrison] - Fix updated plugin not being installed

## Version 0.1.3 (11/21/2016)

- [John Harrison] - Fix Foodcritic complaints
- [John Harrison] - Fix Bukkit plugins not being deleted with bukkit_plugin's delete action
- [John Harrison] - Add support for external Spigot and Bukkit jars

## Version 0.1.2 (9/15/2016)

- [John Harrison] - Fix a bug causing the config not to update properly

## Version 0.1.1 (9/9/2016)

- [John Harrison] - Add support for installing Bukkit plugins from [bukkit.org](https://www.bukkit.org/)
- [John Harrison] - Install plugins with links

## Version 0.1.0 (9/4/2016)

- [John Harrison] - Add support for vanilla Minecraft servers
- [John Harrison] - Add support for Spigot/Bukkit servers
# minecraft-server cookbook

## Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage](#usage)
   1. [Recipes](#recipes)
   2. [Resources](#resources)
       * [minecraft_depend](#minecraft_depend)
       * [minecraft_server](#minecraft_server)
       * [server_properties](#server_properties)
       * [minecraft_service](#minecraft_service)
       * [spigot_server](#spigot_server)
       * [spigot_yml](#spigot_yml)
       * [bukkit_server](#bukkit_server)
       * [bukkit_yml](#bukkit_yml)
       * [bukkit_plugin](#bukkit_plugin)
       * [bukkit_plugin_config](#bukkit_plugin_config)
       * [build_tools](#build_tools)
       * [bungeecord_server](#bungeecord_server)
       * [bungeecord_config_yml](#bungeecord_config_yml)
   3. [Example Usage](#example-usage)

## Description
A simple cookbook for installing and maintaining multiple types of Minecraft servers.

It currently supports 4 different type of Minecraft servers:

* [Spigot](https://www.spigotmc.org)
* [Bungeecord](https://www.spigotmc.org/wiki/bungeecord/)
* [Bukkit](https://bukkit.org)
* [Vanilla](https://minecraft.net)

It also has support for [Spigot's BuildTools](https://www.spigotmc.org/wiki/buildtools/).

If you find any bugs or have any ideas of how this cookbook could be improved, don't be afraid to create an issue on the [GitHub page](https://github.com/Mac-Genius/minecraft-server/issues)!

## Requirements

### Chef

* Chef 12.5+

### Platforms

* Centos 6+
* Ubuntu 14+

*Note: On some distros of Linux, when trying to log into a GNU screen, you might receive a similar error to this: "Cannot open your terminal '/dev/pts/0' - please check."*
*You will need to execute `script /dev/null` to gain access to it. This is because the screen was initially owned by root before the current user. If you have a way to fix this securely (no chmodding /dev/pts/x) please fill free to post an [issue](https://github.com/Mac-Genius/minecraft-server/issues).*

## Usage

In your Berksfile include this cookbook by putting `cookbook 'minecraft-server', git: 'git://github.com/Mac-Genius/minecraft-server.git'`. Then inside your metadata.rb file include `depends 'minecraft-server'`.

### Recipes

There are a few recipes, but they are not intended for use! You should use the custom resources provided by this cookbook. These recipes are intended for testing purposes only. They should only be used as examples.

### Resources

---

#### minecraft_depend

This provides all the dependencies for this cookbook, including Java, screen, unzip, and git.

**Actions**

* `:install`: installs the dependencies

**Attributes**

* `name`: the name of the resource
* `install_all`: installs all dependencies needed to run a Minecraft server
* `install_git`: installs git
* `install_java`: installs java
* `install_screen`: installs screen
* `install_unzip`: installs unzip
* `java_flavor`: what kind of java should be installed (oracle, openjdk, etc.)
* `java_version`: the java version that should be installed

---

#### minecraft_server

This will setup the vanilla Minecraft server including the service files.

**Actions**

* `:create`: installs the Minecraft server
* `:update`: updates the Minecraft server's jar and world
* `:delete`: uninstalls the Minecraft server

**Attributes**

* `name`: the name of the server
* `eula`: whether you agree to Minecraft terms of service. You need to agree to it during the `:create` action to ensure the server is created
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `reset_world`: whether to reset the world when using the `:update` action
* `snapshot`: whether the server should be a snapshot
* `version`: the version of minecraft to install. Defaults to the latest version
* `world`: a url to a zipped world file

---

#### server_properties

This will update the server properties

**Actions**

* `:update`: updates the Minecraft server's server.properties file

**Attributes**

* `name`: the name of the server
* `settings`: a hash of the server properties
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`

---

#### minecraft_service

This will create the necessary service files and run, restart, and stop the Minecraft server.

**Actions**

* `:start`: start the Minecraft server
* `:stop`: stop the Minecraft server
* `:restart`: restart the Minecraft server
* `:enable`: enables the Minecraft server to restart after a server reboot
* `:disable`: disables automatic Minecraft startup
* `:create`: creates the service files for the Minecraft server
* `:update`: updates the service files for the Minecraft server
* `:delete`: deletes the service files for the Minecraft server

**Attributes**

* `service_name`: the name of the service for a Minecraft server
* `commands`: a command or list of commands to be ran after a server startes or before a server stops
* `command_delay`: the delay between the execution of Minecraft commands
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `jar_name`: the name of the jar excluding the '.jar' at the end

---

#### spigot_server

This will setup the Spigot Minecraft server including the service files.

**Actions**

* `:create`: installs the Spigot Minecraft server
* `:update`: updates the Spigot Minecraft server's jar and world
* `:delete`: uninstalls the Spigot Minecraft server

**Attributes**

* `name`: the name of the server
* `build_tools_dir`: the directory to put BuildTools. Defaults to `/opt/build_tools`
* `eula`: whether you agree to Minecraft terms of service. You need to agree to it during the `:create` action to ensure the server is created
* `group`: the group permission that owns the server files, defaults to `chefminecraft`
* `jar_source`: the url of an external Spigot jar file
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `reset_world`: whether to reset the world when using the `:update` action
* `version`: the version of minecraft to install. Defaults to the latest version
* `world`: a url to a zipped world file
* `update_jar`: whether to check for a patch for the current version of Spigot

---

#### spigot_yml

This will setup the Spigot server's spigot.yml file.

**Actions**

* `:update`: updates the Spigot server's spigot.yml file
* `:reset`: resets the spigot.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `settings`: the settings for the spigot.yml as a hash
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`

---

#### bukkit_server

This will setup the Bukkit Minecraft server including the service files.

**Actions**

* `:create`: installs the Bukkit Minecraft server
* `:update`: updates the Bukkit Minecraft server's jar and world
* `:delete`: uninstalls the Bukkit Minecraft server

**Attributes**

* `name`: the name of the server
* `build_tools_dir`: the directory to put BuildTools. Defaults to `/opt/build_tools`
* `eula`: whether you agree to Minecraft terms of service. You need to agree to it during the `:create` action to ensure the server is created
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `jar_source`: the url of an external Bukkit jar file
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `reset_world`: whether to reset the world when using the `:update` action
* `version`: the version of minecraft to install. Defaults to the latest version
* `world`: a url to a zipped world file
* `update_jar`: whether to check for a patch for the current version of Bukkit

---

#### bukkit_yml

This will setup the Bukkit server's bukkit.yml file.

**Actions**

* `:update`: updates the Bukkit server's bukkit.yml file
* `:reset`: resets the bukkit.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `settings`: the settings for the bukkit.yml as a hash
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`

---

#### bukkit_plugin

This will install, update, and delete plugins.

**Actions**

* `:install`: installs the Bukkit plugin
* `:update`: updates the Bukkit plugin
* `:delete`: removes the Bukkit plugin

**Attributes**

* `id`: the name of the plugin from the url. ex) http://dev.bukkit.org/bukkit-plugins/<plugin-name-here>
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `servers`: a string or list of server names to install, update, or delete a plugin on
* `version`: the version of the plugin to install. Defaults to the latest version
* `source`: a url to the jar. Only needed if the plugin is not on Bukkit.org. spigotmc.org/resources links do not work because of Cloudflare!

---

#### bukkit_plugin_config

This will allowing adding, editing, and removing items from a plugin's config.yml file or other configurable .yml file.

*`Note: To remove an item from a config file, simply add '$r$' in front of the name of the item to be removed.`*

**Actions**

* `:update`: updates the config file with the settings from the `settings` property
* `:reset`: resets the config file by deleting it and allowing the server to create a new one

**Attributes**

* `:file_name`: the name of the file to edit. the default name is config.yml 
* `:group`: the group permission that owns the config file. defaults to `chefminecraft`
* `:name`: the name of the plugin that the config belongs to. defaults to `chefminecraft`
* `:owner`: the owner permission that owns the config file
* `:path`: the path of the server folder. defaults to `/opt/minecraft_servers`
* `:servers`: a string or an array of strings containing the servers with the plugin to be updated
* `:settings`: a hash containing the settings to be changed

---

#### build_tools

This will setup BuildTools for creating the Bukkit and Spigot jars. When using the spigot_server/bukkit_server resource, that resource will automatically build the jars. You do not need to use this.

**Actions**

* `:install`: installs BuildTools 
* `:reset`: resets the bukkit.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `source`: the link to BuildTools. defaults to the latest stable version
* `update_jar`: whether the current version of Spigot or Bukkit should be updated
* `version`: the version of Spigot or Bukkit to build

---

#### bungeecord_server

This will setup the Bungeecord Proxy server including the service files.

**Actions**

* `:create`: installs the Bunegeecord server
* `:update`: updates the Bunegeecord server's jar
* `:delete`: uninstalls the Bunegeecord server

**Attributes**

* `name`: the name of the server
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `jar_source`: the url of an external Bungeecord jar file
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`
* `update_jar`: whether to update the Bungeecord jar
* `version`: the version of minecraft to install. defaults to the latest version

---

#### bungeecord_config_yml

This will setup the Bungeecord server's config.yml file.

**Actions**

* `:update`: updates the Bungeecord server's config.yml
* `:reset`: resets the config.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `settings`: the settings for the config.yml as a hash
* `group`: the group permission that owns the server files. defaults to `chefminecraft`
* `owner`: the owner permission that owns the server files. defaults to `chefminecraft`
* `path`: the path to the server directory. defaults to `/opt/minecraft_servers`

---

### Example Usage

#### Creating a vanilla server

```ruby
# installs all dependencies
minecraft_depend 'dependencies' do
  install_all true
end

# installs the server and service files
minecraft_server 'test' do
  eula true
  action :create
end

# set properties for the server
server_properties 'test' do
  settings({
    :motd => 'Welcome to a Chef example server!',
    :enable_command_block => true,
    :difficulty => 3
  })
end

# starts the server
minecraft_service 'test' do
  commands 'say Server is now online!'
  action :start
end
```

#### Updating a vanilla server

```ruby
# updates the server version and resets the world
# this will automatically stop and restart your server
minecraft_server 'test' do
  reset_world true
  version '1.9.4'
  action :update
end
```

#### Update the properties of a vanilla server

```ruby
# starts the server
minecraft_service 'test' do
  commands ['say The server is restarting!', 'say It will be back soon!']
  action :stop
end

# set properties for the server
server_properties 'test' do
  settings({
    :motd => 'Welcome to a Chef example server!',
    :enable_command_block => true,
    :difficulty => 3
  })
end

# starts the server
minecraft_service 'test' do
  commands 'say Server is now online!'
  action :start
end
```

#### Delete a vanilla server

```ruby
# uninstalls the server and service files
minecraft_server 'test' do
  action :delete
end
```

#### Create a Spigot or Bukkit server

(replace spigot with bukkit to create a bukkit server)

```ruby
# installs all dependencies
minecraft_depend 'dependencies' do
  install_all true
end

# installs the server and service files
spigot_server 'test' do
  eula true
  action :create
end

# set properties for the server
server_properties 'test' do
  settings({
    :motd => 'Welcome to a Chef example server!',
    :enable_command_block => true,
    :difficulty => 3
  })
end

# update the spigot.yml file
spigot_yml 'test' do
  settings({
    settings => {
      :debug => true
    }
  })
end

bukkit_plugin 'worldedit' do
  servers 'test'
  action :install
end

bukkit_plugin 'Essentials' do
  source 'https://hub.spigotmc.org/jenkins/job/spigot-essentials/lastSuccessfulBuild/artifact/Essentials/target/Essentials-2.x-SNAPSHOT.jar'
  servers 'test'
  action :install
end

# Updates Essentials' config.yml file
# $r$ removes a settings
bukkit_plugin_config 'Essentials' do
  servers 'test'
  settings ({
      'debug' => true,
      'player-commands' => [
        '$r$compass',
        '$r$warp'
      ]
  })
end

# starts the server
minecraft_service 'test' do
  commands 'say Server is now online!'
  action :start
end
```

#### Create a Bungeecord server

(replace spigot with bukkit to create a bukkit server)

```ruby
# installs all dependencies
minecraft_depend 'dependencies' do
  install_all true
end

# installs the server and service files
bungeecord_server 'test' do
  action :create
end

# set properties for the server
bungeecord_config_yml node['minecraft']['server-name'] do
  settings ({
  'listeners' => [
      {
        'motd' => '&1A Generic motd',
        'host' => '0.0.0.0:25565',
        'max_players' => 30,
        'force_default_server' => true
      }
    ],
    'ip_forward' => true
  })
  action :update
end

# starts the server
minecraft_service 'test' do
  action :start
end
```
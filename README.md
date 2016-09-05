# minecraft-server cookbook

## Description
A simple cookbook for installing and maintaining Minecraft servers.

It currently supports 3 different type of Minecraft servers:

* [Spigot](https://www.spigotmc.org)
* [Bukkit](https://bukkit.org)
* [Vanilla](https://minecraft.net)

## Requirements

### Chef

* Chef 12.5+

### Platforms

* Centos 6+
* Ubuntu 14+

## Usage

In your Berksfile include this cookbook by putting `cookbook 'minecraft-server', git: 'git://github.com/Mac-Genius/minecraft-server.git'`. Then inside your metadata.rb file include `depends 'minecraft-server'`.

### Recipes

There are no recipes! You can use the custom resources to create a server.

### Resources

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

#### minecraft_server

This will setup the vanilla Minecraft server including the service files.

**Actions**

* `:create`: installs the Minecraft server
* `:update`: updates the Minecraft server's jar and world
* `:delete`: uninstalls the Minecraft server

**Attributes**

* `name`: the name of the server
* `eula`: whether you agree to Minecraft terms of service. You need to agree to it during the `:create` action to ensure the server is created
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory
* `reset_world`: whether to reset the world when using the `:update` action
* `snapshot`: whether the server should be a snapshot
* `version`: the version of minecraft to install. Defaults to the latest version
* `world`: a url to a zipped world file

#### server_properties

This will update the server properties

**Actions**

* `:update`: updates the Minecraft server's server.properties file

**Attributes**

* `name`: the name of the server
* `settings`: a hash of the server properties
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory

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
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory
* `jar_name`: the name of the jar excluding the '.jar' at the end
* `delay`: the amount of time to wait for a server to start or stop

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
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory
* `reset_world`: whether to reset the world when using the `:update` action
* `version`: the version of minecraft to install. Defaults to the latest version
* `world`: a url to a zipped world file
* `update_jar`: whether to check for a patch for the current version of Spigot

#### spigot_yml

This will setup the Spigot server's spigot.yml file.

**Actions**

* `:update`: updates the Minecraft server's jar and world
* `:reset`: resets the spigot.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `settings`: the settings for the spigot.yml as a hash
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory

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
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory
* `reset_world`: whether to reset the world when using the `:update` action
* `version`: the version of minecraft to install. Defaults to the latest version
* `world`: a url to a zipped world file
* `update_jar`: whether to check for a patch for the current version of Bukkit

#### bukkit_yml

This will setup the Bukkit server's spigot.yml file.

**Actions**

* `:update`: updates the Minecraft server's jar and world
* `:reset`: resets the bukkit.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `settings`: the settings for the bukkit.yml as a hash
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory

#### build_tools

This will setup BuildTools for creating the Bukkit and Spigot jars

**Actions**

* `:install`: installs BuildTools 
* `:reset`: resets the bukkit.yml file back to its default form

**Attributes**

* `name`: the name of the server
* `group`: the group permission that owns the server files
* `owner`: the owner permission that owns the server files
* `path`: the path to the server directory
* `source`: the link to BuildTools. defaults to the latest stable version
* `update_jar`: whether the current version of Spigot or Bukkit should be updated
* `version`: the version of Spigot or Bukkit to build

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

# starts the server
minecraft_service 'test' do
  commands 'say Server is now online!'
  action :start
end
```

# This recipe is intended for testing purposes only. Please use the custom resources provided by this cookbook
# for creating a Minecraft server.

minecraft_depend 'install' do
  install_all true
end

bungeecord_server 'bungeecord' do
  version 'latest'
  action :create
end

bungeecord_config_yml 'bungeecord' do
  settings ({
      'listeners' => [
          {
              'motd' => '&1A Generic motd',
              'host' => '0.0.0.0:25565',
              'max_players' => 30,
              'force_default_server' => true,
              'priorities' => [
                  'default',
                  '$r$lobby'
              ]
          }
      ],
      'servers' => {
          '$r$lobby' => {},
          'default' => {
              'motd' => 'A Spigot Minecraft server created by Chef!',
              'address' => 'localhost:25566',
              'restricted' => false
          }
      },
      'ip_forward' => true
  })
  action :update
end

minecraft_service 'bungeecord' do
  action :enable
end

minecraft_service 'bungeecord' do
  action :start
end

spigot_server 'default' do
  eula true
  version 'latest'
  jar_source node['minecraft']['jar_source']
  action :create
end

bukkit_plugin 'Essentials' do
  servers 'default'
  source 'https://hub.spigotmc.org/jenkins/job/spigot-essentials/lastSuccessfulBuild/artifact/Essentials/target/Essentials-2.x-SNAPSHOT.jar'
  action :install
end

server_properties 'default' do
  settings ({
      'motd' => 'A Spigot Minecraft server created by Chef!',
      'server_port' => 25566,
      'online_mode' => false
  })
  action :update
end

spigot_yml 'default' do
  settings ({
      'settings' => {
          'bungeecord' => true
      }
  })
  action :update
end

minecraft_service 'default' do
  action :enable
end

minecraft_service 'default' do
  action :start
end
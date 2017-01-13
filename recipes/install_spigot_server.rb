# This recipe is intended for testing purposes only. Please use the custom resources provided by this cookbook
# for creating a Minecraft server.

minecraft_depend 'install' do
  install_all true
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

bukkit_plugin 'WorldEdit' do
  servers 'default'
  action :install
end

server_properties 'default' do
  settings ({
      'motd' => 'A vanilla Minecraft server created by Chef!'
  })
  action :update
end

minecraft_service 'default' do
  action :enable
end

minecraft_service 'default' do
  action :start
end
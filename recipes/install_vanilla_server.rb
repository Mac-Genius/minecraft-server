# This recipe is intended for testing purposes only. Please use the custom resources provided by this cookbook
# for creating a Minecraft server.

minecraft_depend 'install' do
  install_all true
end

minecraft_server 'default' do
  eula true
  version 'latest'
  action :create
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
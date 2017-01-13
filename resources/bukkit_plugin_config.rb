resource_name :bukkit_plugin_config
provides :bukkit_plugin_config

property :file_name, String, default: 'config.yml'
property :group, String, default: 'chefminecraft'
property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :servers, [Array, String], required: true
property :settings, Hash, default: {}

default_action :update

action_class do
  require 'yaml'
  include Minecraft_Server::Utils
end

action :update do
  servers = new_resource.servers
  if servers.is_a?(String)
    servers = [servers]
  end
  servers.each do |server|
    if ::File.exist?("#{new_resource.path}/#{server}/plugins/#{new_resource.name}/#{new_resource.file_name}")
      ruby_block "edit #{new_resource.name} #{new_resource.file_name}" do
        block do
          old = read_yml("#{new_resource.path}/#{server}/plugins/#{new_resource.name}/#{new_resource.file_name}")
          puts 'old'
          puts old.to_s
          new = replace_yml(old, new_resource.settings)
          write_yml("#{new_resource.path}/#{server}/plugins/#{new_resource.name}/#{new_resource.file_name}", new.to_yaml(options = {:line_width => -1}))
        end
        not_if { new_resource.settings.empty? }
      end
    else
      minecraft_service "#{server}_start" do
        service_name server
        action :start
      end
      minecraft_service "#{server}_stop" do
        service_name server
        action :stop
      end
      ruby_block "edit #{new_resource.name} #{new_resource.file_name}" do
        block do
          old = read_yml("#{new_resource.path}/#{server}/plugins/#{new_resource.name}/#{new_resource.file_name}")
          puts 'old'
          puts old.to_s
          new = replace_yml(old, new_resource.settings)
          write_yml("#{new_resource.path}/#{server}/plugins/#{new_resource.name}/#{new_resource.file_name}", new.to_yaml(options = {:line_width => -1}))
        end
        not_if { new_resource.settings.empty? }
      end
    end
  end
end

action :reset do
  servers = new_resource.servers
  if servers.is_a?(String)
    servers = [servers]
  end
  servers.each do |server|
    file "#{new_resource.path}/#{server}/plugins/#{new_resource.name}/#{new_resource.file_name}" do
      action :delete
    end
  end
end
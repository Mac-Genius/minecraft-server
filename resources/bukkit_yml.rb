resource_name :bukkit_yml
provides :bukkit_yml

property :group, String, default: 'chefminecraft'
property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :settings, Hash, default: {}

default_action :update

action_class do
  require 'yaml'
  include Minecraft_Server::Utils
end

action :update do
  if ::File.exist?("#{new_resource.path}/#{new_resource.name}/bukkit.yml")
    ruby_block 'edit bukkit.yml' do
      block do
        old = read_yml("#{new_resource.path}/#{new_resource.name}/bukkit.yml")
        puts 'old'
        puts old.to_s
        new = replace_yml(old, new_resource.settings)
        write_yml("#{new_resource.path}/#{new_resource.name}/bukkit.yml", YAML.dump(new))
      end
      not_if { new_resource.settings.empty? }
    end
  else
    minecraft_service "#{new_resource.name}_start" do
      service_name new_resource.name
      action :start
    end
    minecraft_service "#{new_resource.name}_stop" do
      service_name new_resource.name
      action :stop
    end
    ruby_block 'edit bukkit.yml' do
      block do
        old = read_yml("#{new_resource.path}/#{new_resource.name}/bukkit.yml")
        puts 'old'
        puts old.to_json
        new = replace_yml(old, new_resource.settings)
        write_yml("#{new_resource.path}/#{new_resource.name}/bukkit.yml", YAML.dump(new))
      end
      not_if { new_resource.settings.empty? }
    end
  end
end

action :reset do
  file "#{new_resource.path}/#{new_resource.name}/bukkit.yml" do
    action :delete
  end
end
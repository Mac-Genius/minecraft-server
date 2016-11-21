resource_name :spigot_yml
provides :spigot_yml

property :group, String, default: 'chefminecraft'
property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :settings, Hash, default: {}

default_action :update

action_class do
  require 'yaml'

  def read_yml(file)
    content = ''
    filelines = ::IO.readlines(file)
    filelines.each do |line|
      unless line[0].eql? '#'
        content = content + line
      end
    end
    YAML.load(content)
  end

  def write_yml(file, content)
    header = ''
    filelines = ::IO.readlines(file)
    filelines.each do |line|
      if line[0].eql? '#'
        header = header + line
      end
    end
    final = header + "\n#{content}"
    ::IO.write(file, final)
  end

  def replace_yml(old, new)
    new.keys.each do |key|
      if new[key].is_a?(Hash)
        unless old[key].nil?
          old[key] = replace_yml(old[key], new[key])
        end
      else
        unless old[key].nil?
          unless old[key].eql? new[key]
            old[key] = new[key]
          end
        end
      end
    end
    old
  end
end

action :update do
  if ::File.exist?("#{new_resource.path}/#{new_resource.name}/spigot.yml")
    ruby_block 'edit spigot.yml' do
      block do
        puts 'here'
        old = read_yml("#{new_resource.path}/#{new_resource.name}/spigot.yml")
        puts old.to_s
        puts new_resource.settings.to_s
        new = replace_yml(old, new_resource.settings)
        write_yml("#{new_resource.path}/#{new_resource.name}/spigot.yml", YAML.dump(new))
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
    ruby_block 'edit spigot.yml' do
      block do
        old = read_yml("#{new_resource.path}/#{new_resource.name}/spigot.yml")
        new = replace_yml(old, new_resource.settings)
        write_yml("#{new_resource.path}/#{new_resource.name}/spigot.yml", YAML.dump(new))
      end
      not_if { new_resource.settings.empty? }
    end
  end
end

action :reset do
  file "#{new_resource.path}/#{new_resource.name}/spigot.yml" do
    action :delete
  end
end
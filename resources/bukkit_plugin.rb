resource_name :bukkit_plugin
provides :bukkit_plugin

property :group, String, default: 'chefminecraft'
property :id, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :servers, [Array, String], required: true
property :source, String, default: ''
property :version, String, default: 'latest'

default_action :install

action_class do
  include Minecraft_Server::Web::BUKKIT

  def copy_plugin(name)
    if new_resource.servers.is_a?(String)
      if ::File.exist?("#{new_resource.path}/#{new_resource.servers}")
        unless ::File.exist?("#{new_resource.path}/#{new_resource.servers}/plugins")
          ::FileUtils.mkdir("#{new_resource.path}/#{new_resource.servers}/plugins")
          ::FileUtils.chown(new_resource.owner, new_resource.group, "#{new_resource.path}/#{new_resource.servers}/plugins")
        end
        if ::File.exist?("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar")
          ::FileUtils.rm("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar")
        end
        ::FileUtils.cp("#{Chef::Config[:file_cache_path]}/#{name}.jar", "#{new_resource.path}/#{new_resource.servers}/plugins")
      end
    else
      new_resource.servers.each do |server|
        if ::File.exist?("#{new_resource.path}/#{server}")
          unless ::File.exist?("#{new_resource.path}/#{server}/plugins")
            ::FileUtils.mkdir("#{new_resource.path}/#{server}/plugins")
            ::FileUtils.chown(new_resource.owner, new_resource.group, "#{new_resource.path}/#{server}/plugins")
          end
          if ::File.exist?("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar")
            ::FileUtils.rm("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar")
          end
          ::FileUtils.cp("#{Chef::Config[:file_cache_path]}/#{name}.jar", "#{new_resource.path}/#{new_resource.servers}/plugins")
        end
      end
    end
  end
end

action :install do
  link = new_resource.source
  name = new_resource.id
  if new_resource.source.eql? ''
    plugin = get_plugin(id, new_resource.version)
    unless plugin.nil?
      if plugin[:download].nil?
        Chef::Application.fatal!("Invalid version: #{new_resource.version}!", 1)
      else
        link = plugin[:download]
        name = plugin[:name]
      end
    end
  end
  remote_file name do
    source link
    owner new_resource.owner
    group new_resource.group
    path "#{Chef::Config[:file_cache_path]}/#{name}.jar"
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar") }
  end
  ruby_block 'copy plugin' do
    block do
      copy_plugin(name)
    end
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar") }
  end
  file "#{Chef::Config[:file_cache_path]}/#{name}.jar" do
    action :delete
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.servers}/plugins/#{name}.jar") }
  end
end

action :update do
  link = new_resource.source
  name = new_resource.id
  if new_resource.source.eql? ''
    plugin = get_plugin(id, new_resource.version)
    unless plugin.nil?
      if plugin[:download].nil?
        Chef::Application.fatal!("Invalid version: #{new_resource.version}!", 1)
      else
        link = plugin[:download]
        name = plugin[:name]
      end
    end
  end
  remote_file name do
    source link
    owner new_resource.owner
    group new_resource.group
    path "#{Chef::Config[:file_cache_path]}/#{name}.jar"
  end
  ruby_block 'copy plugin' do
    block do
      copy_plugin(name)
    end
  end

  file "#{Chef::Config[:file_cache_path]}/#{name}.jar" do
    action :delete
  end
end

action :delete do
  ruby_block "delete #{new_resource.name}" do
    block do
      servers = new_resource.servers.is_a?(String) ? [new_resource.servers] : new_resource.servers
      servers.each do |server|
        if ::File.exist?("#{new_resource.path}/#{server}") && ::File.exist?("#{new_resource.path}/#{server}/plugins")
          ::Dir.entries("#{new_resource.path}/#{server}/plugins").each do |file|
            if ::File.extname(file).eql?('.jar')
              matches = /#{new_resource.name}/i.match(file)
              unless matches.nil?
                ::FileUtils.rm("#{new_resource.path}/#{server}/plugins/#{file}")
              end
            end
          end
        end
      end
    end
  end
end
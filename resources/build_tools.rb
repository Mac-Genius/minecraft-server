resource_name :build_tools
provides :build_tools

property :group, String, default: 'chefminecraft'
property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/build_tools'
property :source, String, default: 'https://hub.spigotmc.org/jenkins/job/BuildTools/lastStableBuild/artifact/target/BuildTools.jar'
property :update_jar, [String, TrueClass, FalseClass], default: false
property :version, String, default: 'latest'

default_action :nothing

action_class do
  def get_latest_version
    versions = []
    ::Dir.entries(new_resource.path).each do |file|
      unless file.eql? 'BuildTools.jar'
        if ::File.extname(file).eql?('.jar') && ::File.basename(file).include?('spigot-')
          versions.push(file)
        end
      end
    end
    latest = ''
    major = -1
    minor = -1
    patch = -1
    versions.each do |version|
      temp = version.gsub(/spigot-/, '').gsub(/.jar/, '')
      versionSplit = temp.split(/\./)
      if versionSplit[0].to_i > major
        major = versionSplit[0].to_i
        minor = versionSplit[1].to_i
        patch = versionSplit[2].to_i
        latest = "#{versionSplit[0]}.#{versionSplit[1]}.#{versionSplit[2]}"
      elsif versionSplit[0].to_i == major
        if versionSplit[1].to_i > minor
          major = versionSplit[0].to_i
          minor = versionSplit[1].to_i
          patch = versionSplit[2].to_i
          latest = "#{versionSplit[0]}.#{versionSplit[1]}.#{versionSplit[2]}"
        elsif versionSplit[1].to_i == minor
          if versionSplit[2].to_i > patch
            major = versionSplit[0].to_i
            minor = versionSplit[1].to_i
            patch = versionSplit[2].to_i
            latest = "#{versionSplit[0]}.#{versionSplit[1]}.#{versionSplit[2]}"
          end
        end
      end
    end
    latest
  end
end

action :install do
  directory new_resource.path do
    owner new_resource.owner
    group new_resource.group
    action :create
    not_if { ::Dir.exist?(new_resource.path) }
  end

  remote_file "#{new_resource.path}/BuildTools.jar" do
    source new_resource.source
    owner new_resource.owner
    group new_resource.group
    action :create
    not_if { ::File.exist?("#{new_resource.path}/BuildTools.jar") }
  end
end

action :update do
  directory new_resource.path do
    owner new_resource.owner
    group new_resource.group
    action :create
    not_if { ::Dir.exist?(new_resource.path) }
  end

  remote_file "#{new_resource.path}/BuildTools.jar" do
    source new_resource.source
    owner new_resource.owner
    group new_resource.group
    action :create
  end
end

action :delete do
  directory new_resource.path do
    owner new_resource.owner
    group new_resource.group
    recursive true
    action :delete
    only_if { ::Dir.exist?(new_resource.path) }
  end
end

action :build do
  build_tools 'install' do
    action :install
    not_if { ::File.exist?("#{new_resource.path}/BuildTools.jar") }
  end

  current_version = nil

  ruby_block 'get latest version' do
    block do
      current_version = new_resource.version.eql?('latest') ? get_latest_version : new_resource.version
    end
  end

  if new_resource.version.eql?('latest') || new_resource.update_jar || !::File.exist?("#{new_resource.path}/spigot-#{current_version}.jar")
    bash "Build v#{new_resource.version}" do
      cwd new_resource.path
      code <<-EOH
  java -jar BuildTools.jar --rev #{new_resource.version}
      EOH
    end

    ruby_block 'refresh current version' do
      block do
        node.default['spigot']['current_version'] = new_resource.version.eql?('latest') ? get_latest_version : new_resource.version
      end
    end

    ruby_block 'verify build' do
      block do
        unless ::File.exist?("#{new_resource.path}/spigot-#{node['spigot']['current_version']}.jar")
          Chef::Application.fatal!("#{node['spigot']['current_version']} is an invalid version! Please enter a valid version.", 1)
        end
      end
    end

    file 'spigot.jar' do
      path lazy { "#{new_resource.path}/spigot-#{node['spigot']['current_version']}.jar" }
      owner new_resource.owner
      group new_resource.group
      action :create
    end

    file 'craftbukkit.jar' do
      path lazy { "#{new_resource.path}/craftbukkit-#{node['spigot']['current_version']}.jar" }
      owner new_resource.owner
      group new_resource.group
      action :create
    end

    file "#{new_resource.path}/working_version.txt" do
      owner new_resource.owner
      group new_resource.group
      action :create
      not_if { ::File.exist?("#{new_resource.path}/working_version.txt") }
    end

    ruby_block 'update working_version' do
      block do
        file = Chef::Util::FileEdit.new("#{new_resource.path}/working_version.txt")
        file.search_file_replace_line(/[0-9]+\.[0-9]+\.[0-9]+/, lazy { node['spigot']['current_version'] })
        file.insert_line_if_no_match(/[0-9]+\.[0-9]+\.[0-9]+/, lazy { node['spigot']['current_version'] })
        file.write_file
      end
    end
  else
    ruby_block 'refresh current version' do
      block do
        node.default['spigot']['current_version'] = new_resource.version.eql?('latest') ? get_latest_version : new_resource.version
      end
    end
  end
end
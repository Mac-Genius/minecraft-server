# This resource provides basic setup for a vanilla Minecraft server.

resource_name :minecraft_server
provides :minecraft_server

property :eula, [String, TrueClass, FalseClass], default: false
property :group, String, default: 'chefminecraft'
property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :reset_world, [String, TrueClass, FalseClass], default: false
property :snapshot, kind_of: [TrueClass, FalseClass], default: false
property :version, String, default: 'latest'
property :world, String, default: ''

default_action :create

action_class do
  require 'net/http'
  require 'json'
  include Minecraft_Server::Utils

  def fetch_version_manifest
    uri = URI.parse('https://launchermeta.mojang.com/mc/game/version_manifest.json')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)

    JSON.parse(http.request(request).body)
  end

  def fetch_version_metadata(version, snapshot)
    manifest = fetch_version_manifest

    latestversion = ''
    if snapshot
      latestversion = manifest['latest']['snapshot']
    else
      latestversion = manifest['latest']['release']
    end

    latestdata = nil
    currentdata = nil

    manifest['versions'].each do |item|
      if item['id'].eql? version
        currentdata = item
        break
      end
      if item['id'].eql? latestversion
        latestdata = item
      end
    end

    url = ''

    if currentdata != nil
      url = currentdata['url']
    else
      url = latestdata['url']
    end

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)

    JSON.parse(http.request(request).body)
  end

  def get_version_url(version, snapshot)
    data = fetch_version_metadata(version, snapshot)
    data['downloads']['server']['url']
  end

  def get_latest_version(snapshot)
    data = fetch_version_metadata('latest', snapshot)
    data['id']
  end

  def find_world_file(folder)
    folders = []
    files = ::Dir.entries(folder)
    files.each do |file|
      if file != '.' && file != '..'
        if ::File.directory?("#{folder}/#{file}")
          folders.push("#{folder}/#{file}")
        elsif ::File.file?("#{folder}/#{file}") && ::File.basename("#{folder}/#{file}").eql?('level.dat')
          return ::File.dirname("#{folder}/#{file}")
        end
      end
    end
    folders.each do |folderName|
      temp = find_world_file(folderName)
      unless temp.nil?
        return temp
      end
    end
    return nil
  end
end

action :create do
  user 'chefminecraft' do
    comment 'The default user for running Minecraft servers'
    manage_home false
    password '$1$fJ1ih5nr$gvyz.EjtpQnITcUddzM9k1'
    action node['etc']['passwd']['chefminecraft'] != nil || new_resource.owner != 'chefminecraft' ? :nothing : :create
  end

  currentVersion = new_resource.version.eql?('latest') ? get_latest_version(new_resource.snapshot) : new_resource.version

  directory "#{new_resource.path}/#{new_resource.name}" do
    owner new_resource.owner
    group new_resource.group
    recursive true
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}") }
  end

  remote_file "#{new_resource.path}/#{new_resource.name}/minecraft_server.#{new_resource.version}.jar" do
    data = fetch_version_metadata(new_resource.version, new_resource.snapshot)
    path "#{new_resource.path}/#{new_resource.name}/minecraft_server.#{data['id']}.jar"
    source data['downloads']['server']['url']
    owner new_resource.owner
    group new_resource.group
    mode '0755'
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/minecraft_server.#{new_resource.version}.jar") }
  end

  minecraft_service new_resource.name do
    owner new_resource.owner
    group new_resource.group
    jar_name "minecraft_server.#{currentVersion}"
    path new_resource.path
    action :create
  end

  unless ::File.exist?("#{new_resource.path}/#{new_resource.name}/eula.txt")
    minecraft_service "#{new_resource.name}_start" do
      service_name new_resource.name
      action :start
    end

    minecraft_service "#{new_resource.name}_stop" do
      service_name new_resource.name
      action :stop
    end
  end

  ruby_block 'update eula' do
    block do
      file = Chef::Util::FileEdit.new("#{new_resource.path}/#{new_resource.name}/eula.txt")
      file.search_file_replace_line(/^eula=/, "eula=#{new_resource.eula.to_s}")
      file.write_file
    end
  end

  unless new_resource.world.eql? ''
    headers = {}
    if ::File.extname(new_resource.world).eql?('') && ::File.basename(new_resource.world).eql?('download')
      headers = {"Referer" => ::File.dirname(new_resource.world)}
    end
    remote_file "#{new_resource.path}/#{new_resource.name}/world.zip" do
      source new_resource.world
      owner new_resource.owner
      group new_resource.group
      mode '0755'
      headers(headers)
      action :create
      not_if { ::Dir.exist?("#{new_resource.path}/#{new_resource.name}/world") }
    end

    bash 'extract world' do
      cwd "#{new_resource.path}/#{new_resource.name}"
      code <<-EOH
unzip #{new_resource.path}/#{new_resource.name}/world.zip -d world
      EOH
      only_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/world.zip") }
    end

    ruby_block 'move world' do
      block do
        folder = find_world_file("#{new_resource.path}/#{new_resource.name}/world")
        puts folder
        ::FileUtils.mv(folder, "#{::File.dirname(folder)}/world1")
        ::FileUtils.mv("#{::File.dirname(folder)}/world1", "#{new_resource.path}/#{new_resource.name}")
        ::FileUtils.rm_rf("#{new_resource.path}/#{new_resource.name}/world")
        ::FileUtils.mv("#{new_resource.path}/#{new_resource.name}/world1","#{new_resource.path}/#{new_resource.name}/world")
      end
      only_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/world.zip") }
    end

    file "#{new_resource.path}/#{new_resource.name}/world.zip" do
      action :delete
      only_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/world.zip") }
    end

    bash 'update world perms' do
      cwd "#{new_resource.path}/#{new_resource.name}"
      code <<-EOH
chown -R #{new_resource.owner}:#{new_resource.group} world/
      EOH
    end
  end
end

action :update do
  running = is_running(new_resource.name)
  minecraft_service "#{new_resource.name}_stop" do
    service_name new_resource.name
    action :stop
    only_if { running }
  end

  currentVersion = new_resource.version.eql?('latest') ? get_latest_version(new_resource.snapshot) : new_resource.version

  minecraft_service new_resource.name do
    owner new_resource.owner
    group new_resource.group
    jar_name "minecraft_server.#{currentVersion}"
    path new_resource.path
    action :update
  end

  ruby_block 'remove old jar' do
    block do
      jar = ''
      ::Dir.entries("#{new_resource.path}/#{new_resource.name}").each do |file|
        if ::File.extname(file).eql?('.jar')
          jar = file
          break
        end
      end
      unless jar.eql? ''
        unless jar.eql? "minecraft_server.#{currentVersion}.jar"
          ::FileUtils.rm("#{new_resource.path}/#{new_resource.name}/#{jar}")
        end
      end
    end
  end

  remote_file "#{new_resource.path}/#{new_resource.name}/minecraft_server.#{new_resource.version}.jar" do
    data = fetch_version_metadata(new_resource.version, new_resource.snapshot)
    path "#{new_resource.path}/#{new_resource.name}/minecraft_server.#{data['id']}.jar"
    source data['downloads']['server']['url']
    owner new_resource.owner
    group new_resource.group
    mode '0755'
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/minecraft_server.#{new_resource.version}.jar") }
  end

  if new_resource.world.eql? ''
    if new_resource.reset_world
      ruby_block "delete #{new_resource.name} world folder" do
        block do
          ::FileUtils.rm_rf("#{new_resource.path}/#{new_resource.name}/world")
        end
        only_if { ::Dir.exist?("#{new_resource.path}/#{new_resource.name}/world") }
      end
    end
  else
    if new_resource.reset_world
      ruby_block "delete #{new_resource.name} world folder" do
        block do
          ::FileUtils.rm_rf("#{new_resource.path}/#{new_resource.name}/world")
        end
        only_if { ::Dir.exist?("#{new_resource.path}/#{new_resource.name}/world") }
      end

      headers = {}
      if ::File.extname(new_resource.world).eql?('') && ::File.basename(new_resource.world).eql?('download')
        headers = {"Referer" => ::File.dirname(new_resource.world)}
      end
      remote_file "#{new_resource.path}/#{new_resource.name}/world.zip" do
        source new_resource.world
        owner new_resource.owner
        group new_resource.group
        mode '0755'
        headers(headers)
        action :create
        not_if { ::Dir.exist?("#{new_resource.path}/#{new_resource.name}/world") }
      end

      bash 'extract world' do
        cwd "#{new_resource.path}/#{new_resource.name}"
        code <<-EOH
  unzip #{new_resource.path}/#{new_resource.name}/world.zip -d world
        EOH
        only_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/world.zip") }
      end

      ruby_block 'move world' do
        block do
          folder = find_world_file("#{new_resource.path}/#{new_resource.name}/world")
          puts folder
          ::FileUtils.mv(folder, "#{::File.dirname(folder)}/world1")
          ::FileUtils.mv("#{::File.dirname(folder)}/world1", "#{new_resource.path}/#{new_resource.name}")
          ::Dir.rmdir("#{new_resource.path}/#{new_resource.name}/world")
          ::FileUtils.mv("#{new_resource.path}/#{new_resource.name}/world1","#{new_resource.path}/#{new_resource.name}/world")
        end
        only_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/world.zip") }
      end

      file "#{new_resource.path}/#{new_resource.name}/world.zip" do
        action :delete
        only_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/world.zip") }
      end

      bash 'update world perms' do
        cwd "#{new_resource.path}/#{new_resource.name}"
        code <<-EOH
  chown -R #{new_resource.owner}:#{new_resource.group} world/
        EOH
      end
    end
  end

  minecraft_service "#{new_resource.name}_start" do
    service_name new_resource.name
    action :start
    only_if { running }
  end
end

action :delete do
  minecraft_service "#{new_resource.name}_stop" do
    service_name new_resource.name
    action :stop
  end

  minecraft_service new_resource.name do
    action :delete
  end

  ruby_block "delete #{new_resource.name} folder" do
    block do
      ::FileUtils.rm_rf("#{new_resource.path}/#{new_resource.name}")
    end
  end
end
# This resource provides basic setup for a Spigot Minecraft server.

resource_name :spigot_server
provides :spigot_server

property :build_tools_dir, String, default: '/opt/build_tools'
property :eula, [String, TrueClass, FalseClass], default: false
property :group, String, default: 'chefminecraft'
property :jar_source, String, default: ''
property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :reset_world, [String, TrueClass, FalseClass], default: false
property :update_jar, [String, TrueClass, FalseClass], default: false
property :version, String, default: 'latest'
property :world, String, default: ''

default_action :create

action_class do
  include Minecraft_Server::Utils

  def get_spigot_version
    unless ::File.exist?("#{new_resource.build_tools_dir}/working_version.txt")
      Chef::Application.fatal!("Failed to find the working_version.txt file in #{build_tools_dir}!", 1)
    end
    ::File.read("#{build_tools_dir}/working_version.txt").rstrip
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
    nil
  end
end

action :create do
  user 'chefminecraft' do
    comment 'The default user for running Minecraft servers'
    manage_home false
    password '$1$fJ1ih5nr$gvyz.EjtpQnITcUddzM9k1'
    action node['etc']['passwd']['chefminecraft'] != nil || new_resource.owner != 'chefminecraft' ? :nothing : :create
  end

  directory "#{new_resource.path}/#{new_resource.name}" do
    owner new_resource.owner
    group new_resource.group
    recursive true
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}") }
  end

  if new_resource.jar_source.eql? ''
    build_tools 'create jar' do
      version new_resource.version
      update_jar new_resource.update_jar
      path new_resource.build_tools_dir
      owner new_resource.owner
      group new_resource.group
      action :build
    end

    ruby_block 'copy jar' do
      block do
        ::FileUtils.cp("#{new_resource.build_tools_dir}/spigot-#{node['spigot']['current_version']}.jar", "#{new_resource.path}/#{new_resource.name}")
      end
    end
  else
    remote_file "#{new_resource.path}/#{new_resource.name}/spigot.jar" do
      source new_resource.jar_source
      owner new_resource.owner
      group new_resource.group
      action :create
    end
  end

  minecraft_service new_resource.name do
    owner new_resource.owner
    group new_resource.group
    if new_resource.jar_source.eql? ''
      jar_name lazy { "spigot-#{node['spigot']['current_version']}" }
    else
      jar_name 'spigot'
    end
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

  build_tools 'create jar' do
    version new_resource.version
    update_jar new_resource.update_jar
    action :build
    only_if { new_resource.jar_source.eql? '' && new_resource.update_jar }
  end

  minecraft_service new_resource.name do
    owner new_resource.owner
    group new_resource.group
    if new_resource.jar_source.eql? ''
      jar_name lazy { "spigot-#{node['spigot']['current_version']}" }
    else
      jar_name 'spigot'
    end
    path new_resource.path
    action :update
    only_if { new_resource.update_jar }
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
      puts jar
      unless jar.eql? ''
        if jar.eql?("spigot-#{node['spigot']['current_version']}.jar")
          ::FileUtils.rm("#{new_resource.path}/#{new_resource.name}/#{jar}")
        elsif jar.eql?('spigot.jar')
          ::FileUtils.rm("#{new_resource.path}/#{new_resource.name}/#{jar}")
        end
      end
    end
    only_if { new_resource.update_jar }
  end


  ruby_block 'copy jar' do
    block do
      ::FileUtils.cp("#{new_resource.build_tools_dir}/spigot-#{node['spigot']['current_version']}.jar", "#{new_resource.path}/#{new_resource.name}")
    end
    only_if { new_resource.jar_source.eql? '' && new_resource.update_jar }
  end

  remote_file "#{new_resource.path}/#{new_resource.name}/spigot.jar" do
    source new_resource.jar_source
    owner new_resource.owner
    group new_resource.group
    action :create
    only_if { new_resource.update_jar && !new_resource.jar_source.eql?('') }
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
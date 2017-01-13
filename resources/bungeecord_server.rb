resource_name :bungeecord_server
provides :bungeecord_server

property :group, String, default: 'chefminecraft'
property :jar_source, String, default: ''
property :name, String, name_property: 'bungeecord'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :update_jar, [String, TrueClass, FalseClass], default: false
property :version, String, default: 'latest'

default_action :create

action_class do
  def get_bungeecord_url(version)
    if version.eql? 'latest'
      return 'http://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar'
    else
      return "http://ci.md-5.net/job/BungeeCord/#{version}/artifact/bootstrap/target/BungeeCord.jar"
    end
  end

  def is_running
    if ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.name}.service")
      cmd = Mixlib::ShellOut.new("systemctl status minecraft_#{new_resource.name}.service")
      cmd.run_command
      if cmd.exitstatus == 0
        true
      else
        false
      end
    elsif ::File.exist?("/etc/init.d/minecraft_#{new_resource.name}")
      cmd = Mixlib::ShellOut.new("service minecraft_#{new_resource.name} status")
      cmd.run_command
      if cmd.exitstatus == 0
        true
      else
        false
      end
    end
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

  directory "#{new_resource.path}/#{new_resource.name}/logs" do
    owner new_resource.owner
    group new_resource.group
    recursive true
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}/logs") }
  end

  if new_resource.jar_source.eql? ''
    remote_file "#{new_resource.path}/#{new_resource.name}/Bungeecord.jar" do
      source get_bungeecord_url(new_resource.version)
      owner new_resource.owner
      group new_resource.group
      action :create
    end
  else
    remote_file "#{new_resource.path}/#{new_resource.name}/Bungeecord.jar" do
      source new_resource.jar_source
      owner new_resource.owner
      group new_resource.group
      action :create
    end
  end

  minecraft_service new_resource.name do
    owner new_resource.owner
    group new_resource.group
    jar_name 'Bungeecord'
    is_bungeecord true
    path new_resource.path
    additional_cmd '| tee logs/latest.log'
    action :create
  end
end

action :update do
  running = is_running
  minecraft_service "#{new_resource.name}_stop" do
    service_name new_resource.name
    is_bungeecord true
    action :stop
    only_if { running }
  end

  if new_resource.update_jar
    file "#{new_resource.path}/#{new_resource.name}/Bungeecord.jar" do
      action :delete
    end

    if new_resource.jar_source.eql? ''
      remote_file "#{new_resource.path}/#{new_resource.name}/Bungeecord.jar" do
        source get_bungeecord_url(new_resource.version)
        owner new_resource.owner
        group new_resource.group
        action :create
      end
    else
      remote_file "#{new_resource.path}/#{new_resource.name}/Bungeecord.jar" do
        source new_resource.jar_source
        owner new_resource.owner
        group new_resource.group
        action :create
      end
    end
  end

  minecraft_service "#{new_resource.name}_start" do
    service_name new_resource.name
    is_bungeecord true
    action :start
    only_if { running }
  end
end

action :delete do
  minecraft_service "#{new_resource.name}_stop" do
    service_name new_resource.name
    is_bungeecord true
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
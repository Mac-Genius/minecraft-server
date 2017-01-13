resource_name :minecraft_service
provides :minecraft_service

property :additional_cmd, String, default: ''
property :commands, [Array, String], default: []
property :command_delay, [Integer, String], default: 2
property :group, String, default: 'chefminecraft'
property :is_bungeecord, [TrueClass, FalseClass], default: false
property :jar_name, String, default: 'minecraft_server.jar'
property :owner, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :service_name, String, name_property: 'default'

default_action :nothing

action_class do
  include Minecraft_Server::Utils

  def is_done_loading(file)
    if ::File.exists?(file)
      filelines = ::IO.readlines(file)
      filelines.each do |line|
        found = line.match(/Done \([0-9]*\.[0-9]*s\)\! For help, type "help" or "\?"/)
        if found.nil?
          found = line.match(/Listening on (\/[0-9.a-zA-Z]+):([0-9]+)/)
          unless found.nil?
            return true
          end
        else
          return true
        end
      end
      false
    else
      false
    end
  end
end

action :start do
  if ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") || ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}")
    service "minecraft_#{new_resource.service_name}" do
      action :start
    end
    ruby_block 'start_wait' do
      block do
        count = 0
        puts ''
        while is_running(new_resource.service_name) && !is_done_loading("#{new_resource.path}/#{new_resource.service_name}/logs/latest.log") do
          if count % 5 == 0
            puts 'Waiting for the server to finish starting...'
          end
          count += 1
          sleep(1)
        end
      end
    end
    ruby_block 'execute commands' do
      block do
        if new_resource.commands.is_a?(String)
          cmd = Mixlib::ShellOut.new("su #{new_resource.owner} -c 'screen -S minecraft_#{new_resource.name} -p 0 -X stuff \"#{new_resource.commands}^M\"'")
          cmd.run_command
        else
          new_resource.commands.each do |command|
            cmd = Mixlib::ShellOut.new("su #{new_resource.owner} -c 'screen -S minecraft_#{new_resource.name} -p 0 -X stuff \"#{command}^M\"'")
            cmd.run_command
            sleep(new_resource.command_delay.to_i)
          end
        end
      end
    end
  else
    log 'no service' do
      message "The service \"minecraft_#{new_resource.service_name}\" does not exist!"
      level :error
    end
  end
end

action :stop do
  if ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") || ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}")
    ruby_block 'execute commands' do
      block do
        if new_resource.commands.is_a?(String)
          cmd = Mixlib::ShellOut.new("su #{new_resource.owner} -c 'screen -S minecraft_#{new_resource.name} -p 0 -X stuff \"#{new_resource.commands}^M\"'")
          cmd.run_command
        else
          new_resource.commands.each do |command|
            cmd = Mixlib::ShellOut.new("su #{new_resource.owner} -c 'screen -S minecraft_#{new_resource.name} -p 0 -X stuff \"#{command}^M\"'")
            cmd.run_command
            sleep(new_resource.command_delay.to_i)
          end
        end
      end
    end

    service "minecraft_#{new_resource.service_name}" do
      service_name "minecraft_#{new_resource.service_name}"
      action :stop
    end

    ruby_block 'stop_wait' do
      block do
        count = 0
        puts ''
        while is_running(new_resource.service_name) do
          if count % 5 == 0
            puts 'Waiting for the server to shut down...'
          end
          count += 1
          sleep(1)
        end
      end
    end
  else
    log 'no service' do
      message "The service \"minecraft_#{new_resource.service_name}\" does not exist!"
      level :error
    end
  end
end

action :restart do
  if ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") || ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}")
    service "minecraft_#{new_resource.service_name}_stop" do
      service_name "minecraft_#{new_resource.service_name}.service"
      action :stop
    end
    ruby_block 'restart_wait' do
      block do
        count = 0
        puts ''
        while is_running(new_resource.service_name) do
          if count % 5 == 0
            puts 'Waiting for the server to shut down...'
          end
          count += 1
          sleep(1)
        end
      end
    end
    service "minecraft_#{new_resource.service_name}_start" do
      service_name "minecraft_#{new_resource.service_name}.service"
      action :start
    end

    count = 0
    puts ''
    while is_running(new_resource.service_name) && !is_done_loading("#{new_resource.path}/#{new_resource.service_name}/logs/latest.log") do
      if count % 5 == 0
        puts 'Waiting for the server to finish starting...'
      end
      count += 1
      sleep(1)
    end
  else
    log 'no service' do
      message "The service \"minecraft_#{new_resource.service_name}\" does not exist!"
      level :error
    end
  end
end

action :enable do
  if ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") || ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}")
    service "minecraft_#{new_resource.service_name}" do
      action :enable
    end
  else
    log 'no service' do
      message "The service \"minecraft_#{new_resource.service_name}\" does not exist!"
      level :error
    end
  end
end

action :disable do
  if ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") || ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}")
    service "minecraft_#{new_resource.service_name}" do
      action :disable
    end
  else
    log 'no service' do
      message "The service \"minecraft_#{new_resource.service_name}\" does not exist!"
      level :error
    end
  end
end

action :create do
  if node["platform"].eql? "centos"
    if node['platform_version'].slice(0, 1).eql? '6'
      template "/etc/init.d/minecraft_#{new_resource.service_name}" do
        source 'minecraft.sh.erb'
        cookbook 'minecraft-server'
        variables({
                      :user => new_resource.owner,
                      :name => new_resource.service_name,
                      :jar_name => "#{new_resource.jar_name}.jar",
                      :directory => "#{new_resource.path}/#{new_resource.service_name}",
                      :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                      :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}",
                      :init_function => '/etc/init.d/functions'
                  })
        mode '0755'
        not_if { ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}") }
      end

      execute 'add script to chkconfig' do
        command "chkconfig --add minecraft_#{new_resource.service_name}"
      end
    elsif node['platform_version'].slice(0, 1).eql? '7'
      template "/etc/systemd/system/minecraft_#{new_resource.service_name}.service" do
        source 'minecraft.service.erb'
        cookbook 'minecraft-server'
        variables({
                      :user => new_resource.owner,
                      :group => new_resource.group,
                      :name => new_resource.service_name,
                      :jar_name => "#{new_resource.jar_name}.jar",
                      :directory => "#{new_resource.path}/#{new_resource.service_name}",
                      :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                      :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}"
                  })
        mode '0755'
        not_if { ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") }
      end

      execute 'reload systemctl' do
        command 'systemctl daemon-reload'
      end

    else
      log 'unsupported version!' do
        level :warn
        message 'You are using an unsupported linux distribution!'
      end
    end
  elsif node["platform"].eql? "ubuntu"
    if node['platform_version'].slice(0, 2).eql? '14'
      template "/etc/init.d/minecraft_#{new_resource.service_name}" do
        source 'minecraft.sh.erb'
        cookbook 'minecraft-server'
        variables(
            lazy {
              {
                  :user => new_resource.owner,
                  :name => new_resource.service_name,
                  :jar_name => "#{new_resource.jar_name}.jar",
                  :directory => "#{new_resource.path}/#{new_resource.service_name}",
                  :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                  :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}",
                  :init_function => '/lib/lsb/init-functions'
              }
            }
        )
        mode '0755'
        not_if { ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}") }
      end
    elsif node['platform_version'].slice(0, 2).eql? '16'
      template "/etc/systemd/system/minecraft_#{new_resource.service_name}.service" do
        source 'minecraft.service.erb'
        cookbook 'minecraft-server'
        variables({
                      :user => new_resource.owner,
                      :group => new_resource.group,
                      :name => new_resource.service_name,
                      :jar_name => "#{new_resource.jar_name}.jar",
                      :directory => "#{new_resource.path}/#{new_resource.service_name}",
                      :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                      :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}"
                  })
        mode '0755'
        not_if { ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") }
      end

      execute 'reload systemctl' do
        command 'systemctl daemon-reload'
      end

    else
      log 'unsupported version!' do
        level :warn
        message 'You are using an unsupported linux distribution!'
      end
    end
  end
end

action :update do
  if node["platform"].eql? "centos"
    if node['platform_version'].slice(0, 1).eql? '6'
      template "/etc/init.d/minecraft_#{new_resource.service_name}" do
        source 'minecraft.sh.erb'
        cookbook 'minecraft-server'
        variables({
                      :user => new_resource.owner,
                      :name => new_resource.service_name,
                      :jar_name => "#{new_resource.jar_name}.jar",
                      :directory => "#{new_resource.path}/#{new_resource.service_name}",
                      :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                      :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}",
                      :init_function => '/etc/init.d/functions'
                  })
        mode '0755'
      end
    elsif node['platform_version'].slice(0, 1).eql? '7'
      template "/etc/systemd/system/minecraft_#{new_resource.service_name}.service" do
        source 'minecraft.service.erb'
        cookbook 'minecraft-server'
        variables({
                      :user => new_resource.owner,
                      :group => new_resource.group,
                      :name => new_resource.service_name,
                      :jar_name => "#{new_resource.jar_name}.jar",
                      :directory => "#{new_resource.path}/#{new_resource.service_name}",
                      :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                      :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}"
                  })
        mode '0755'
      end

      execute 'reload systemctl' do
        command 'systemctl daemon-reload'
      end

    else
      log 'unsupported version!' do
        level :warn
        message 'You are using an unsupported linux distribution!'
      end
    end
  elsif node["platform"].eql? "ubuntu"
    if node['platform_version'].slice(0, 2).eql? '14'
      template "/etc/init.d/minecraft_#{new_resource.service_name}" do
        source 'minecraft.sh.erb'
        cookbook 'minecraft-server'
        variables(
            {
                :user => new_resource.owner,
                :name => new_resource.service_name,
                :jar_name => "#{new_resource.jar_name}.jar",
                :directory => "#{new_resource.path}/#{new_resource.service_name}",
                :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}",
                :init_function => '/lib/lsb/init-functions'
            }
        )
        mode '0755'
      end
    elsif node['platform_version'].slice(0, 2).eql? '16'
      template "/etc/systemd/system/minecraft_#{new_resource.service_name}.service" do
        source 'minecraft.service.erb'
        cookbook 'minecraft-server'
        variables({
                      :user => new_resource.owner,
                      :group => new_resource.group,
                      :name => new_resource.service_name,
                      :jar_name => "#{new_resource.jar_name}.jar",
                      :directory => "#{new_resource.path}/#{new_resource.service_name}",
                      :stop_command => new_resource.is_bungeecord ? 'end' : 'stop',
                      :add_cmd => new_resource.additional_cmd.eql?('') ? '' : " #{new_resource.additional_cmd}"
                  })
        mode '0755'
      end

      execute 'reload systemctl' do
        command 'systemctl daemon-reload'
      end

    else
      log 'unsupported version!' do
        level :warn
        message 'You are using an unsupported linux distribution!'
      end
    end
  end
end

action :delete do
  if node["platform"].eql? "centos"
    if node['platform_version'].slice(0, 1).eql? '6'
      template "/etc/init.d/minecraft_#{new_resource.service_name}" do
        source 'minecraft.sh.erb'
        cookbook 'minecraft-server'
        action :delete
        only_if { ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}") }
      end
    elsif node['platform_version'].slice(0, 1).eql? '7'
      template "/etc/systemd/system/minecraft_#{new_resource.service_name}.service" do
        source 'minecraft.service.erb'
        cookbook 'minecraft-server'
        action :delete
        only_if { ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") }
      end

      execute 'reload systemctl' do
        command 'systemctl daemon-reload'
      end

    else
      log 'unsupported version!' do
        level :warn
        message 'You are using an unsupported linux distribution!'
      end
    end
  elsif node["platform"].eql? "ubuntu"
    if node['platform_version'].slice(0, 2).eql? '14'
      template "/etc/init.d/minecraft_#{new_resource.service_name}" do
        source 'minecraft.sh.erb'
        cookbook 'minecraft-server'
        action :delete
        only_if { ::File.exist?("/etc/init.d/minecraft_#{new_resource.service_name}") }
      end
    elsif node['platform_version'].slice(0, 2).eql? '16'
      template "/etc/systemd/system/minecraft_#{new_resource.service_name}.service" do
        source 'minecraft.service.erb'
        cookbook 'minecraft-server'
        action :delete
        only_if { ::File.exist?("/etc/systemd/system/minecraft_#{new_resource.service_name}.service") }
      end

      execute 'reload systemctl' do
        command 'systemctl daemon-reload'
      end

    else
      log 'unsupported version!' do
        level :warn
        message 'You are using an unsupported linux distribution!'
      end
    end
  end
end
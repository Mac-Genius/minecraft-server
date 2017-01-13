resource_name :server_properties
provides :server_properties

property :name, String, name_property: 'default'
property :owner, String, default: 'chefminecraft'
property :group, String, default: 'chefminecraft'
property :path, String, default: '/opt/minecraft_servers'
property :settings, Hash, default: {}

default_action :update

action_class do
  def read_properties(file)
    content = {}
    filelines = ::IO.readlines(file)
    filelines.each do |line|
      unless line[0].eql? '#'
        array = line.strip.gsub(/-/, '_').split(/=/)
        content[array[0]] = array[1].nil? ? '' : array[1]
      end
    end
    content
  end

  def write_properties(file, content)
    header = ''
    filelines = ::IO.readlines(file)
    filelines.each do |line|
      if line[0].eql? '#'
        header = header + line
      end
    end
    content.keys.each do |key|
      header = header + "#{key.gsub(/_/, '-')}=#{content[key]}\n"
    end
    ::IO.write(file, header)
  end

  def replace_properties(old, new)
    new.keys.each do |key|
      if key.is_a?(Symbol)
        if old[key.to_s].nil?
          old[key.to_s] = new[key]
        else
          unless old[key.to_s].eql? new[key]
            old[key.to_s] = new[key]
          end
        end
      else
        if old[key].nil?
          old[key] = new[key]
        else
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
  unless ::File.exist?("#{new_resource.path}/#{new_resource.name}")
    log 'not a valid server' do
      message 'That server does not exist!'
      level :error
    end
    exit 1
  end

  if ::File.exist?("#{new_resource.path}/#{new_resource.name}/server.properties") && ::File.read("#{new_resource.path}/#{new_resource.name}/server.properties").split('\n').length < 3
    minecraft_service "#{new_resource.name}_start_config_initial" do
      service_name new_resource.name
      action :start
    end

    minecraft_service "#{new_resource.name}_stop_config_initial" do
      service_name new_resource.name
      action :stop
    end
  end

  ruby_block 'update_config' do
    block do
      old = read_properties("#{new_resource.path}/#{new_resource.name}/server.properties")
      new = replace_properties(old, new_resource.settings)
      write_properties("#{new_resource.path}/#{new_resource.name}/server.properties", new)
    end
  end
end
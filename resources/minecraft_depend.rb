resource_name :minecraft_depend
provides :minecraft_depend

property :name, String, name_property: 'default'
property :install_all, [String, TrueClass, FalseClass], default: false
property :install_git, [String, TrueClass, FalseClass], default: false
property :install_java, [String, TrueClass, FalseClass], default: false
property :install_screen, [String, TrueClass, FalseClass], default: false
property :install_unzip, [String, TrueClass, FalseClass], default: false
property :java_flavor, String, default: 'oracle'
property :java_version, String, default: '8'

default_action :nothing

action :install do
  package 'screen' do
    package_name 'screen'
    action :install
    only_if { new_resource.install_screen || new_resource.install_all }
  end

  package 'unzip' do
    package_name 'unzip'
    action :install
    only_if { new_resource.install_unzip || new_resource.install_all }
  end

  package 'git' do
    package_name 'git'
    action :install
    only_if { new_resource.install_git || new_resource.install_all }
  end

  if new_resource.install_java || new_resource.install_all
    node.default['java']['install_flavor'] = new_resource.java_flavor
    node.default['java']['jdk_version'] = new_resource.java_version
    node.default['java']['oracle']['accept_oracle_download_terms'] = true
    include_recipe 'java::default'
  end
end
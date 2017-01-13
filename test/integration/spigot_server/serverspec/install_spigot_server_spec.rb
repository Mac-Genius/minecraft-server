require 'spec_helper'

describe 'minecraft_server::install_spigot_server' do
  describe package 'git' do
    it { should be_installed }
  end

  describe package 'screen' do
    it { should be_installed }
  end

  describe file '/usr/bin/java' do
    it { should be_file }
  end

  describe package 'unzip' do
    it { should be_installed }
  end

  describe file '/opt/minecraft_servers/default' do
    it { should be_directory }
  end

  describe file '/opt/minecraft_servers/default/plugins' do
    it { should be_directory }
  end

  describe file '/opt/minecraft_servers/default/plugins/Essentials.jar' do
    it { should be_file }
  end

  describe file '/opt/minecraft_servers/default/plugins/WorldEdit.jar' do
    it { should be_file }
  end

  describe service 'minecraft_default' do
    it { should be_enabled }
  end

  describe service 'minecraft_default' do
    it { should be_running }
  end

  describe file '/opt/minecraft_servers/default/server.properties' do
    its('content') { should match(%r{motd=A vanilla Minecraft server created by Chef\\!}) }
  end
end
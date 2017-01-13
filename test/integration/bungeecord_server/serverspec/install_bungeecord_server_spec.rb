require 'spec_helper'

describe 'minecraft_server::install_bungeecord_server' do
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

  # Bungeecord server testing

  describe file '/opt/minecraft_servers/bungeecord' do
    it { should be_directory }
  end

  describe file '/opt/minecraft_servers/bungeecord/config.yml' do
    its('content') { should match(%r{default:[\s]*motd: A Spigot Minecraft server created by Chef![\s]*address: localhost:25566[\s]*restricted: false}) }
  end

  describe service 'minecraft_bungeecord' do
    it { should be_enabled }
  end

  describe service 'minecraft_bungeecord' do
    it { should be_running }
  end

  # describe file '/opt/minecraft_servers/bungeecord' do
  #   its('content') { should match(%r{}) }
  # end
  #
  # describe file '/opt/minecraft_servers/bungeecord' do
  #   its('content') { should match(%r{}) }
  # end
  #
  # describe file '/opt/minecraft_servers/bungeecord' do
  #   its('content') { should match(%r{}) }
  # end

  # Default Spigot server

  describe file '/opt/minecraft_servers/default/plugins/Essentials.jar' do
    it { should be_file }
  end

  describe service 'minecraft_default' do
    it { should be_enabled }
  end

  describe service 'minecraft_default' do
    it { should be_running }
  end

  describe file '/opt/minecraft_servers/default/server.properties' do
    its('content') { should match(%r{motd=A Spigot Minecraft server created by Chef\\!}) }
  end

  describe file '/opt/minecraft_servers/default/spigot.yml' do
    its('content') { should match(%r{bungeecord: true}) }
  end
end
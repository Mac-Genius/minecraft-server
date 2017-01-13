require 'yaml'

module Minecraft_Server
  module Utils
    def read_yml(file)
      index = 1
      content = ''
      filelines = ::IO.readlines(file)
      filelines.each do |line|
        if line.strip.eql?('') || line[0].eql?('#')
          content = content + "$comment#{index}$: \"#{line.strip.gsub(/"/, '%QUOTE%')}\"\n"
          index += 1
        else
          content = content + line
        end
      end
      puts content
      YAML.load(content)
    end

    def write_yml(file, content)
      final = ''
      content.lines.each do |line|
        found = line.match(/"\$comment[0-9]+\$": "([\d\D]*)"([\D]+)/)
        if found.nil?
          blankline = line.match(/"\$comment[0-9]+\$": ''([\D]+)/)
          if blankline.nil?
            final = final + line
          else
            final = final + blankline.captures[0]
          end
        else
          final = final + found.captures[0].gsub(/%QUOTE%/, '"') + found.captures[1]
        end
      end
      ::IO.write(file, final)
    end

    def replace_yml(old, new)
      if new.is_a?(Array)
        index = 0
        new.each do |object|
          if object.is_a?(String) && object.start_with?('$r$')
            old.delete_if do |to_remove|
              if to_remove.is_a?(String) && to_remove.eql?(object.gsub(/\$r\$/, ''))
                true
              else
                false
              end
            end
          end
          index += 1
        end
        index = 0
        new.each do |object|
          if object.is_a?(Hash) || object.is_a?(Array)
            old[index] = replace_yml(old[index], object)
            index += 1
          else
            unless object.is_a?(String) && object.start_with?('$r$')
              old[index] = object
              index += 1
            end
          end
        end
        old
      else
        new.keys.each do |key|
          if key.start_with? '$r$'
            unless old[key.gsub(/\$r\$/, '')].nil?
              old.delete(key.gsub(/\$r\$/, ''))
            end
          elsif new[key].is_a?(Hash) || new[key].is_a?(Array)
            if old[key].nil?
              old[key] = new[key]
            else
              old[key] = replace_yml(old[key], new[key])
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

    def is_running(name)
      if ::File.exist?("/etc/systemd/system/minecraft_#{name}.service")
        cmd = Mixlib::ShellOut.new("systemctl status minecraft_#{name}.service")
        cmd.run_command
        if cmd.exitstatus == 0
          true
        else
          false
        end
      elsif ::File.exist?("/etc/init.d/minecraft_#{name}")
        cmd = Mixlib::ShellOut.new("service minecraft_#{name} status")
        cmd.run_command
        if cmd.exitstatus == 0
          true
        else
          false
        end
      else
        false
      end
    end
  end
end
require 'nokogiri'
require 'open-uri'

module Minecraft_Server
  module Web
    module BUKKIT
      def get_plugin_page(id)
        doc = Nokogiri::HTML(open("https://dev.bukkit.org/bukkit-plugins/#{id}"))
      end

      def get_plugin_author(doc)
        authors = []
        array = doc.css("#project-overview .main-details .main-info .authors li")
        array.each do |author|
          authors.push(author.css("a").first.text)
        end
        authors
      end

      def get_plugin_name(doc)
        doc.css("#page #hd h1")[1].text.strip
      end

      def get_plugin_link(id, version)
        # Get the page of the plugin
        doc = Nokogiri::HTML(open("https://dev.bukkit.org/bukkit-plugins/worldedit/files/"))

        # Find the amount of pages
        array = doc.css(".listing-pagination-bottom .listing-pagination-pages li").slice(1, doc.css(".listing-pagination-bottom .listing-pagination-pages li").length - 2)
        array.each do |page|

          # Get each pagination page and find all versions and links
          page_doc = Nokogiri::HTML(open("https://dev.bukkit.org/bukkit-plugins/#{id}/files/?page=#{page.text}"))

          # if the version is latest grab the first item
          if version.eql? 'latest'
            download_page = Nokogiri::HTML(open("https://dev.bukkit.org#{page_doc.css(".listing-container-inner .listing tbody tr .col-file a").first['href']}"))
            return download_page.css(".user-action-download span a").first['href']
          end

          page_doc.css(".listing-container-inner .listing tbody tr").each do |item|
            if ::File.extname(item.css(".col-filename").text).rstrip.eql? '.jar'

              # extract the version from the title
              current_version = /([0-9]+.[0-9]+[.]{0,1}[0-9]*)/.match(item.css(".col-file").text)[0]
              find_version_array = version.split('.')
              if find_version_array.length == 2
                find_version_array.push(0)
              end
              current_version_array = current_version.split('.')
              if current_version_array.length == 2
                current_version_array.push(0)
              end
              if current_version[0] < find_version_array[0]
                return nil
              else
                if current_version[0] == find_version_array[0] && current_version[1] < find_version_array[1]
                  return nil
                else
                  if current_version[0] == find_version_array[0] && current_version[1] == find_version_array[1] && current_version[2] < find_version_array[2]
                    return nil
                  else
                    if current_version[0] == find_version_array[0] && current_version[1] == find_version_array[1] && current_version[2] == find_version_array[2]
                      download_page = Nokogiri::HTML(open("https://dev.bukkit.org#{item.css(".col-file a").first['href']}"))
                      return download_page.css(".user-action-download span a").first['href']
                    end
                  end
                end
              end
            end
          end
        end
      end

      def get_plugin(id, version)
        doc = get_plugin_page(id)
        plugin_data = {
            :name => "#{get_plugin_name(doc)}",
            :author => "#{get_plugin_author(doc)}",
            :download => get_plugin_link(id, version)
        }
        plugin_data
      end
    end
  end
end
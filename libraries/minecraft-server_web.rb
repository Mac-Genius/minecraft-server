require 'nokogiri'
require 'open-uri'

module Minecraft_Server
  module Web
    module BUKKIT
      def get_plugin_page(id)
        doc = Nokogiri::HTML(open("https://dev.bukkit.org/projects/#{id}"))
      end

      def get_plugin_author(doc)
        authors = []
        array = doc.css(".cf-sidebar-wrapper .cf-sidebar-inner .project-members li")
        array.each do |author|
          authors.push(author.css(".info-wrapper a span").first.text)
        end
        authors
      end

      def get_plugin_name(doc)
        doc.css(".project-details-container .project-user .project-title a span")[0].text.strip
      end

      def get_plugin_link(id, version)
        # Get the page of the plugin
        doc = Nokogiri::HTML(open("https://dev.bukkit.org/projects/#{id}/files/"))

        # Find the amount of pages
        array = doc.css(".listing-header .b-pagination .b-pagination-list li").slice(0, doc.css(".listing-header .b-pagination .b-pagination-list li").length - 1)
        array.each do |page|

          # Get each pagination page and find all versions and links
          page_doc = Nokogiri::HTML(open("https://dev.bukkit.org/projects/#{id}/files?page=#{page.css('span').first.text}"))

          # if the version is latest grab the first item
          if version.eql? 'latest'
            download_page = "https://dev.bukkit.org#{page_doc.css(".listing-body .listing tbody tr").first.css('.project-file-name .project-file-download-button a').first['href']}"
            return download_page
          end

          page_doc.css(".listing-body .listing tbody tr").each do |item|

            # extract the version from the title
            current_version = /([0-9]+.[0-9]+[.]{0,1}[0-9]*)/.match(item.css(".project-file-name .project-file-name-container a").first.text)[0]
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
                    download_page = "https://dev.bukkit.org#{page_doc.css(".listing-body .listing tbody tr").first.css('.project-file-name .project-file-download-button a').first['href']}"
                    return download_page
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
            :name => get_plugin_name(doc),
            :author => get_plugin_author(doc),
            :download => get_plugin_link(id, version)
        }
        plugin_data
      end
    end
  end
end
require 'rest-client'
require 'nokogiri'


MACHINE_TYPE=0
VIRTUAL_CPUS=1
MEMORY=2
PRICE=3
PREEMPTIBLE_PRICE=4

#page = Nokogiri::HTML("https://cloud.google.com/compute/pricing"))   
page = Nokogiri::HTML(File.read('google.html'))


page.css('div table').each do |div|
  table = div.css('thead th')
  if table[MACHINE_TYPE].text == 'Machine type' and table.size == 5
    div.css('tbody tr').each do |type|
      if type.css('td').size == 5
        machine_type =  type.css('td')[MACHINE_TYPE]
        puts machine_type.text.gsub(/[\n ]/, "")
        puts type.css('td')[VIRTUAL_CPUS].text
        puts type.css('td')[MEMORY].text.sub('GB', '')
        type.css('td')[PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
          puts "#{region}: #{type.css('td')[PRICE][region].sub('$', '')}"  
        end
        type.css('td')[PREEMPTIBLE_PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
          puts "#{region}: #{type.css('td')[PREEMPTIBLE_PRICE][region].sub('$', '')}"  
        end
        
#        puts machine_type.text unless machine_type.nil?
      end
    end
  end
end

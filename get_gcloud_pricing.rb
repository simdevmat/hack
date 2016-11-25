require 'rest-client'
require 'nokogiri'


MACHINE_TYPE=0
VIRTUAL_CPUS=1
MEMORY=2
PRICE=3
PREEMPTIBLE_PRICE=4
CUSTOM_PRICE=1
CUSTOM_PREEMPTIBLE_PRICE=2
#page = Nokogiri::HTML("https://cloud.google.com/compute/pricing"))   
page = Nokogiri::HTML(File.read('google.html'))


custom_types = {}
predefined_types = {}

page.css('div table').each do |div|
  table = div.css('thead th')
  if table[MACHINE_TYPE].text == 'Machine type' and table.size == 5
    div.css('tbody tr').each do |type|
      if type.css('td').size == 5
        machine_type = type.css('td')[MACHINE_TYPE].text.gsub(/[\n ]/, "")
        vcpus        = type.css('td')[VIRTUAL_CPUS].text
        memory       = type.css('td')[MEMORY].text.sub('GB', '')
        preemptible_price = {}
        standard_price = {}
        type.css('td')[PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
          standard_price[region] = type.css('td')[PRICE][region].sub('$', '')
        end
        type.css('td')[PREEMPTIBLE_PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
          preemptible_price[region] = type.css('td')[PREEMPTIBLE_PRICE][region].sub('$', '')
        end
        predefined_types[machine_type] = {
          "vcpus" => vcpus,
          "memory" => memory,
          "standard_prices" => standard_price,
          "preemptible_prices" => preemptible_price,
        } 
      end
    end
  elsif table[MACHINE_TYPE].text == 'Item' and table.size == 3
    div.css('tbody tr').select { |t| t.css('td')[0].text == 'vCPU' or t.css('td')[0].text == 'Memory' }.each do |type|
      name = type.css('td')[0].text.downcase
      custom_types[name] = {
        "standard_prices" => {},
        "preemptible_prices" => {},
      }
      type.css('td')[CUSTOM_PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
        custom_types[name]['standard_prices'][region] = type.css('td')[CUSTOM_PRICE][region].gsub('$', '').gsub(/[\$\s\/]*(vCPU|GB)/, '')
      end
      type.css('td')[CUSTOM_PREEMPTIBLE_PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
        custom_types[name]['preemptible_prices'][region] = type.css('td')[CUSTOM_PREEMPTIBLE_PRICE][region].sub('$', '').gsub(/[\$\s\/]*(vCPU|GB)/, '')
      end
    end
  end
end

puts custom_types
puts predefined_types

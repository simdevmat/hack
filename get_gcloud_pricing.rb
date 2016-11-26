require 'rest-client'
require 'nokogiri'


MACHINE_TYPE=0
VCPUS=1
MEMORY=2
PRICE=3
PREEMPTIBLE_PRICE=4
CUSTOM_PRICE=1
CUSTOM_PREEMPTIBLE_PRICE=2
data = RestClient.get("https://cloud.google.com/compute/pricing")
File.open('google.html', 'w') { |file| file.write(data)}
page = Nokogiri::HTML(data)


custom_types = {}
predefined_types = {}

page.css('div table').each do |div|
  table = div.css('thead th')
  if table[MACHINE_TYPE].text == 'Machine type' and table.size == 5
    div.css('tbody tr').each do |type|
      if type.css('td').size == 5
        machine_type = type.css('td')[MACHINE_TYPE].text.gsub(/[\n ]/, "")
        type.css('td')[MACHINE_TYPE].traverse do |node| 
          if node.text? and node.text =~ /\S/
            machine_type = node.text.gsub(/[\n ]/, "")
            break
          end
        end 
        predefined_types[machine_type] = {}
        type.css('td')[PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
          predefined_types[machine_type][region] = { 
            "vcpus"             => type.css('td')[VCPUS][region] || type.css('td')[VCPUS].text,
            "memory"            => (type.css('td')[MEMORY][region] || type.css('td')[MEMORY].text).sub('GB', ''),
            "standard_price"    => type.css('td')[PRICE][region].sub('$', ''),
            "preemptible_price" => type.css('td')[PREEMPTIBLE_PRICE][region].sub('$', ''),
          } 
        end
      end
    end
  elsif table[MACHINE_TYPE].text == 'Item' and table.size == 3
    div.css('tbody tr').select { |t| t.css('td')[0].text == 'vCPU' or t.css('td')[0].text == 'Memory' }.each do |type|
      name = type.css('td')[0].text.downcase
      custom_types[name] = {}
      type.css('td')[CUSTOM_PRICE].keys.select { |prices| prices.include?('hourly')}.each do |region|
        custom_types[name][region] = {
         'standard_price'     => type.css('td')[CUSTOM_PRICE][region].gsub('$', '').gsub(/[\$\s\/]*(vCPU|GB)/, ''),
         'preemptible_price' => type.css('td')[CUSTOM_PREEMPTIBLE_PRICE][region].sub('$', '').gsub(/[\$\s\/]*(vCPU|GB)/, '')
        }
      end
    end
  end
end


predefined_types.each do |name, regions|
puts name.upcase
  regions.each do |region, data|
    puts "\t#{region.sub(/-.*/, '').upcase}: #{data['vcpus']} #{data['memory']} #{data['standard_price']} #{data['preemptible_price']}"
  end
end

custom_types.each do |name, regions|
  puts "Custom #{name.upcase}"
  regions.each do |region, data|
    puts "\t#{region.sub(/-.*/, '').upcase}: #{data['standard_price']} #{data['preemptible_price']}"
  end
end
    

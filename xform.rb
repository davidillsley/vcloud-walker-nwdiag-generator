require 'json'

def nics_from_vapp(vapp) 
	if vapp["vms"].length != 1
		raise "Not 1 vm inside this vApp #{vapp['name']}"
	end
	ncs = vapp['vms'][0]['network_connections']
	ncs = if ncs.is_a?(Hash) then [ncs] else ncs end # https://github.com/alphagov/vcloud-walker/issues/9
	return ncs.map{ |n| 
			{
				"name" => vapp['name'],
				"network" => n['network'],
				"ip_address" => n['IpAddress']
			}
		}
end

def map_vdc(vdc) 
	nics = vdc["vapps"].map{ |y| nics_from_vapp(y) }.flatten
	return {
		"name" => vdc["name"],
		"networks" => nics.group_by{ |nic| nic['network'] }
	}
end

string = File.open('vdcs.json', 'rb') { |file| file.read }
arr = JSON.parse(string)
res  = arr.map { |x| map_vdc(x) }
#puts res

res.each{|vdc| 
	 File.open("#{vdc['name']}.diag", 'w') { |file| 
	 	file.write("nwdiag {\n inet [shape = cloud];\n inet -- VSE\n")
	    vdc["networks"].each{ |network_name, vms|
			file.write "network #{network_name} {\n VSE;\n"
			vms.sort{ |x,y| x['name'] <=> y['name'] }.each{ |vm|
				vmname = vm['name'].split('.')[0]
				file.write "#{vmname} [address = \"#{vm['ip_address']}\"];\n"
			}
			file.write "}\n"
		}
		file.write "}\n"
	}
}
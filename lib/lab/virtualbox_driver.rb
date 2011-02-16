require 'vm_driver'
require 'nokogiri'

##
## $Id$
##
module Lab
module Drivers
	class VirtualBoxDriver < VmDriver

		attr_accessor :type
		attr_accessor :location

		def initialize(vmid, location=nil)

			@vmid = filter_input(vmid)
			@location = filter_input(location)

			@type = "virtualbox"
			
			## Check to see if we already know this vm, if not, go on location
			vmid_list = get_vm_names
			unless vmid_list.include? @vmid
				raise "Error, no such vm: #{@vmid}" unless @location
				
				if !File.exist?(@location)
					raise ArgumentError,"Error, no vm at: #{@location}"
				end
				
				puts "Registering #{@location}"
				@vmid = register_and_return_vmid
			end
			
			vmInfo = `VBoxManage showvminfo \"#{@vmid}\" --machinereadable`
			@location = vmInfo.scan(/CfgFile=\"(.*?)\"/).flatten.to_s
		end

		def register_and_return_vmid
			
			xml = Nokogiri::XML(File.new(@location))
			vmid = xml.root.xpath("//Machine[@name]")
			
			## only register if we don't already know the vmid
			if !get_vm_names.include? vmid
				system_command("VBoxManage registervm \"#{@location}\"")
			end
			
			return vmid
			
		end

		def unregister
			system_command("VBoxManage unregistervm \"#{@vmid}\"")
		end

		def start
			system_command("VBoxManage startvm \"#{@vmid}\"")
		end

		def stop
			system_command("VBoxManage controlvm \"#{@vmid}\" poweroff")
		end

		def suspend
			system_command("VBoxManage controlvm \"#{@vmid}\" savestate")
		end

		def pause
			system_command("VBoxManage controlvm \"#{@vmid}\" pause")
		end

		def reset
			system_command("VBoxManage controlvm \"#{@vmid}\" reset")
		end

		def create_snapshot(snapshot)
			snapshot = filter_input(snapshot)
			system_command("VBoxManage snapshot \"#{@vmid}\" take " + snapshot)
		end

		def revert_snapshot(snapshot)
			snapshot = filter_input(snapshot)
			system_command("VBoxManage snapshot \"#{@vmid}\" restore " + snapshot)
		end

		def delete_snapshot(snapshot)
			snapshot = filter_input(snapshot)
			system_command("VBoxManage snapshot \"#{@vmid}\" delete " + snapshot)
		end

		def run_command(command, arguments, user, pass)
			command = "VBoxManage guestcontrol exec \"#{@vmid}\" \"#{command}\" --username \"#{user}\"
					 --password \"#{pass}\" --arguments \"#{arguments}\""
			system_command(command)
		end
	
		def copy_from(user, pass, from, to)
			raise "Not supported by Virtual Box"
		end

		def copy_to(user, pass, from, to)
			command = "VBoxManage guestcontrol copyto \"#{@vmid}\" \"#{from}\"  \"#{to}\"
					 --username \"#{user}\" --password \"#{pass}\""
			system_command(command)
		end

		def check_file_exists(user, pass, file)
			raise "Not supported by Virtual Box"
		end

		def create_directory(user, pass, directory)
			command = "VBoxManage guestcontrol createdir \"#{@vmid}\" \"#{directory}\"
					 --username \"#{user}\" --password \"#{pass}\""
			system_command(command)
		end

		def cleanup

		end

		def running?
			## Get running Vms
			get_running_vm_names.include? @vmid
		end
		
		private
		
		def get_vm_names
			## Get Known VMs
			vm_names_and_uuids = `VBoxManage list vms`.split("\n")
			4.times { vm_names_and_uuids.shift }

			vm_names = []
			vm_names_and_uuids.each do |entry|
				vm_names << entry.split('"')[1]
			end			
			
			return vm_names
		end

		def get_vm_uuids
			## Get Known VMs
			vm_names_and_uuids = `VBoxManage list vms`.split("\n")
			4.times { vm_names_and_uuids.shift }

			vm_uuids = []
			vm_names_and_uuids.each do |entry|
				vm_names << entry.split('"')[2]
			end
			
			return vm_uuids
		end
		
		def get_running_vm_names
			## Get Known VMs
			vm_names_and_uuids = `VBoxManage list runningvms`.split("\n")
			4.times { vm_names_and_uuids.shift }

			vm_names = []
			vm_names_and_uuids.each do |entry|
				vm_names << entry.split('"')[1]
			end
			
			return vm_names
		end
	end
end
end

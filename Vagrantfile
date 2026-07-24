Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "rootpath-target"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 1
    vb.name = "rootpath-target"
  end

  config.vm.provision "shell", path: "provisioning/packages.sh"
  config.vm.provision "shell", path: "provisioning/users.sh"
  config.vm.provision "shell", path: "provisioning/services.sh"
  config.vm.provision "shell", path: "provisioning/privesc_a.sh"
  config.vm.provision "shell", path: "provisioning/privesc_b.sh"
  config.vm.provision "shell", path: "provisioning/flags.sh"
end
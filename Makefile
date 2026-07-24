.PHONY: deploy validate reset harden test destroy

deploy:
	vagrant up

validate:
	vagrant ssh -c "sudo bash /vagrant/tests/test_deployment.sh"

reset:
	vagrant ssh -c "sudo bash /vagrant/scripts/reset.sh"

harden:
	vagrant ssh -c "sudo bash /vagrant/scripts/harden.sh"

test:
	vagrant ssh -c "sudo bash /vagrant/tests/test_deployment.sh && sudo bash /vagrant/tests/test_vulnerable.sh"

destroy:
	vagrant destroy -f
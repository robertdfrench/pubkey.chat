all: pubkey regtok instance

build/cloud-init.sh: build/registration_token.json cloud-init.sh
	$(info [Script] Compile Cloud Init Script)
	@cat cloud-init.sh \
		| sed "s/TOKEN/`jq -r '.token' $<`/" \
		| base64 > $@

build/instance.json: build/instance_id.txt
	$(info [Instance] Fetch Instance Details)
	@curl -s "https://api.vultr.com/v2/instances/`cat $<`" \
		-H "Authorization: Bearer ${VULTR_API_KEY}" > $@
	@rm -f build/instance_id.txt

build/instance_id.txt: build/.dir
	$(info [Instance] Lookup Existing Instance)
	@curl -s "https://api.vultr.com/v2/instances" -H "Authorization: Bearer ${VULTR_API_KEY}" \
		| jq -r '.instances[] | select(.hostname == "runner.invalid").id' > $@

build/instance_request.json: instance.json build/plan_id.txt build/region.txt build/os_id.txt \
	build/ssh-key_id.txt build/cloud-init.sh
	$(info [Instance] Prepare a Instance Creation Request)
	@jq \
		--arg os_id `cat build/os_id.txt` \
		--arg plan_id `cat build/plan_id.txt` \
		--arg region `cat build/region.txt` \
		--arg sshkey_id `cat build/ssh-key_id.txt` \
		--arg user_data `cat build/cloud-init.sh` \
		'. + {os_id: $$os_id, plan: $$plan_id, region: $$region, sshkey_id: [$$sshkey_id], user_data: $$user_data}' \
		$< > $@

build/os.json: build/.dir
	$(info [Instance] Fetch Available Operating System Images)
	@curl -s "https://api.vultr.com/v2/os" > $@

build/os_id.txt: build/os.json
	$(info [Instance] Identify Latest Ubuntu Image)
	@jq '.os[] | select(.family == "ubuntu")' $< \
		| jq --slurp 'max_by(.name).id' > $@

build/plan_id.txt: build/plans.json build/region.txt
	$(info [Instance] Identify the Most Appropriate Instance Plan for This Region)
	@jq \
		--arg region `cat build/region.txt` \
		'.plans[] | select(.locations | contains([$$region]))' build/plans.json \
		| jq --slurp --raw-output 'min_by(.monthly_cost).id' > $@

build/plans.json: build/region.txt
	$(info [Instance] Fetch Available Instance Plans)
	@curl -s "https://api.vultr.com/v2/plans" > $@

build/pubkey: build/.dir
	$(info [Pubkey] Import a known SSH pubkey)
	@cp ~/.ssh/id_rsa.pub build/pubkey

build/region.txt: ../config.json build/.dir
	$(info [Instance] Identify Target Region)
	@jq --raw-output '.vultr.principal_region' $< > $@

build/registration_token.json: build/repo_path.txt
	$(info [Token] Create a New Runner Registration Token)
	@curl -s \
		-X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer ${GITHUB_TOKEN}"\
		-H "X-GitHub-Api-Version: 2022-11-28" \
		https://api.github.com/repos/`cat $<`/actions/runners/registration-token \
		> $@

build/repo_path.txt: build/.dir
	$(info [Runner] Identify Repository Path)
	@git remote -v \
		| grep push \
		| awk '{ print $$2 }' \
		| cut -f2 -d':' \
		| sed 's/\.git//' \
		> $@

build/runners.json: build/repo_path.txt
	$(info [Runner] Fetch Existing Runners)
	@curl -s \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer ${GITHUB_TOKEN}" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		https://api.github.com/repos/`cat $<`/actions/runners \
		> $@

build/ssh-key_id.txt: build/.dir
	$(info [Pubkey] Lookup Existing SSH Key)
	@curl -s "https://api.vultr.com/v2/ssh-keys" -H "Authorization: Bearer ${VULTR_API_KEY}" \
		| jq -r '.ssh_keys[] | select(.name == "runner.invalid").id' > $@

build/ssh-key_request.json: pubkey.json build/pubkey
	$(info [Instance] Prepare a Instance Creation Request)
	@jq \
		--arg ssh_key "`cat build/pubkey`" \
		'. + {ssh_key: $$ssh_key}' $< > $@

build/.dir:
	$(info [All] Initialize Local State)
	@mkdir -p build
	@touch $@

# Destroy the instance only if it exists
# P -> Q == !P || Q
clean:
	$(info [All] Destroy any existing infrastructure)
	@(! $(MAKE) instance_exists) || $(MAKE) instance_destroy
	@(! $(MAKE) pubkey_exists) || $(MAKE) pubkey_destroy
	@rm -rf build

instance:
	$(info [Instance] Begin)
	@$(MAKE) instance_exists || $(MAKE) instance_create

instance_ip: build/instance.json
	$(info [Instance] Identify IP Address of Existing Instance)
	@jq -r '.instance.main_ip' $<
	@rm -f $<

instance_create: build/instance_request.json
	$(info [Instance] Create a New Instance)
	@curl -s "https://api.vultr.com/v2/instances" \
		-X POST \
		-H "Authorization: Bearer ${VULTR_API_KEY}" \
		-H "Content-Type: application/json" \
		--data @$<

instance_destroy: build/instance_id.txt
	$(info [Instance] Destroy an Existing Instance)
	@curl -s "https://api.vultr.com/v2/instances/`cat $<`" \
		-X DELETE \
		-H "Authorization: Bearer ${VULTR_API_KEY}"
	@rm -f build/instance_id.txt

instance_exists:
	$(info [Instance] Assert that the Runner Instance Exists)
	@curl -s "https://api.vultr.com/v2/instances" -H "Authorization: Bearer ${VULTR_API_KEY}" \
	| jq -e '.instances[] | select(.hostname == "runner.invalid") | length > 0'

pubkey:
	$(info [Pubkey])
	@$(MAKE) pubkey_exists || $(MAKE) pubkey_create

pubkey_create: build/ssh-key_request.json
	$(info [Pubkey] Create a New Public Key)
	@curl -s "https://api.vultr.com/v2/ssh-keys" \
		-X POST \
		-H "Authorization: Bearer ${VULTR_API_KEY}" \
		-H "Content-Type: application/json" \
		--data @$<

pubkey_destroy: build/ssh-key_id.txt
	$(info [Pubkey] Destroy an Existing Public Key)
	@curl -s "https://api.vultr.com/v2/ssh-keys/`cat $<`" \
		-X DELETE \
		-H "Authorization: Bearer ${VULTR_API_KEY}"
	@rm -f build/ssh-key_id.txt

pubkey_exists:
	$(info [Pubkey] Assert that the Public Key Exists)
	@curl -s "https://api.vultr.com/v2/ssh-keys" -H "Authorization: Bearer ${VULTR_API_KEY}" \
		| jq -e '.ssh_keys[] | select(.name == "runner.invalid") | length > 0'

runner_exists: build/runners.json
	$(info [Runner] Assert That the Runner Exists)
	@jq -e '.runners[] | select(.name == "runner") | length > 0' $<
	@rm -f build/runners.json

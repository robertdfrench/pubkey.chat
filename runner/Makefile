all: pubkey runner

build/instance_id.txt: build/.dir
	$(info + Lookup Existing Instance)
	@curl -s "https://api.vultr.com/v2/instances" -H "Authorization: Bearer ${VULTR_API_KEY}" \
		| jq -r '.instances[] | select(.hostname == "runner.invalid").id' > $@

build/instance_request.json: instance.json build/plan_id.txt build/region.txt build/os_id.txt \
	build/ssh-key_id.txt
	$(info + Prepare a Instance Creation Request)
	@jq \
		--arg plan_id `cat build/plan_id.txt` \
		--arg region `cat build/region.txt` \
		--arg os_id `cat build/os_id.txt` \
		--arg ssh_key_id `cat build/ssh-key_id.txt` \
		'. + {region: $$region, plan: $$plan_id, os_id: $$os_id, ssh_key_id: $$ssh_key_id}' $< > $@

build/plan_id.txt: build/plans.json build/region.txt
	$(info + Identify the Most Appropriate Instance Plan for This Region)
	@jq \
		--arg region `cat build/region.txt` \
		'.plans[] | select(.locations | contains([$$region]))' build/plans.json \
		| jq --slurp --raw-output 'min_by(.monthly_cost).id' > $@

build/plans.json: build/region.txt
	$(info + Fetch Available Instance Plans)
	@curl -s "https://api.vultr.com/v2/plans" > $@

build/os.json: build/.dir
	$(info + Fetch Available Operating System Images)
	@curl -s "https://api.vultr.com/v2/os" > $@

build/os_id.txt: build/os.json
	$(info + Identify Latest Ubuntu Image)
	@jq '.os[] | select(.family == "ubuntu")' $< \
		| jq --slurp 'max_by(.name).id' > $@

build/region.txt: ../config.json build/.dir
	$(info + Identify Target Region)
	@jq --raw-output '.vultr.principal_region' $< > $@

build/ssh-key_id.txt: build/.dir
	$(info + Lookup Existing SSH Key)
	@curl -s "https://api.vultr.com/v2/ssh-keys" -H "Authorization: Bearer ${VULTR_API_KEY}" \
		| jq -r '.ssh_keys[] | select(.name == "runner.invalid").id' > $@

build/ssh-key_request.json: pubkey.json build/pubkey
	$(info + Prepare a Instance Creation Request)
	@jq \
		--arg ssh_key "`cat build/pubkey`" \
		'. + {ssh_key: $$ssh_key}' $< > $@

build/.dir:
	$(info + Initialize Local State)
	@mkdir -p build
	@touch $@

# Destroy the runner only if it exists
# P -> Q == !P || Q
clean:
	$(info + Destroy any existing infrastructure)
	@(! $(MAKE) runner_exists) || $(MAKE) runner_destroy
	@(! $(MAKE) pubkey_exists) || $(MAKE) pubkey_destroy
	@rm -rf build

pubkey:
	$(info [Pubkey])
	@$(MAKE) pubkey_exists || $(MAKE) pubkey_create

pubkey_create: build/ssh-key_request.json
	$(info + Create a New Public Key)
	@curl -s "https://api.vultr.com/v2/ssh-keys" \
		-X POST \
		-H "Authorization: Bearer ${VULTR_API_KEY}" \
		-H "Content-Type: application/json" \
		--data @$<

pubkey_destroy: build/ssh-key_id.txt
	$(info + Destroy an Existing Public Key)
	@curl -s "https://api.vultr.com/v2/ssh-keys/`cat $<`" \
		-X DELETE \
		-H "Authorization: Bearer ${VULTR_API_KEY}"

pubkey_exists:
	$(info + Assert that the Public Key Exists)
	@curl -s "https://api.vultr.com/v2/ssh-keys" -H "Authorization: Bearer ${VULTR_API_KEY}" \
		| jq -e '.ssh_keys[] | select(.name == "runner.invalid") | length > 0'

runner:
	$(info [Runner])
	@$(MAKE) runner_exists || $(MAKE) runner_create

runner_create: build/instance_request.json
	$(info + Create a New Runner Instance)
	@curl -s "https://api.vultr.com/v2/instances" \
		-X POST \
		-H "Authorization: Bearer ${VULTR_API_KEY}" \
		-H "Content-Type: application/json" \
		--data @$<

runner_destroy: build/instance_id.txt
	$(info + Destroy an Existing Runner Instance)
	@curl -s "https://api.vultr.com/v2/instances/`cat $<`" \
		-X DELETE \
		-H "Authorization: Bearer ${VULTR_API_KEY}"
	@rm -f build/instance_id.txt

runner_exists:
	$(info + Assert that the Runner Instance Exists)
	@curl -s "https://api.vultr.com/v2/instances" -H "Authorization: Bearer ${VULTR_API_KEY}" \
	| jq -e '.instances[] | select(.hostname == "runner.invalid") | length > 0'

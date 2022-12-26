all:
	$(MAKE) runner_exists || $(MAKE) create_runner

runner_exists:
	@curl "https://api.vultr.com/v2/instances" -H "Authorization: Bearer ${VULTR_API_KEY}" \
	| jq -e '.instances[] | select(.hostname == "runner.infra.pubkey.chat") | length > 0'

create_runner: build/instance_request.json
	@curl "https://api.vultr.com/v2/instances" \
		-X POST \
		-H "Authorization: Bearer ${VULTR_API_KEY}" \
		-H "Content-Type: application/json" \
		--data @$<

destroy_runner: build/instance_id.txt
	@curl "https://api.vultr.com/v2/instances/`cat $<`" \
		-X DELETE \
		-H "Authorization: Bearer ${VULTR_API_KEY}"

build/instance_id.txt: build/.dir
	@curl "https://api.vultr.com/v2/instances" -H "Authorization: Bearer ${VULTR_API_KEY}" \
	| jq -r '.instances[] | select(.hostname == "runner.infra.pubkey.chat").id' > $@

build/instance_request.json: instance.json build/plan_id.txt build/region.txt build/os_id.txt
	jq \
		--arg plan_id `cat build/plan_id.txt` \
		--arg region `cat build/region.txt` \
		--arg os_id `cat build/os_id.txt` \
		'. + {region: $$region, plan: $$plan_id, os_id: $$os_id}' $< > $@

build/plan_id.txt: build/plans.json build/region.txt
	jq \
		--arg region `cat build/region.txt` \
		'.plans[] | select(.locations | contains([$$region]))' build/plans.json \
		| jq --slurp --raw-output 'min_by(.monthly_cost).id' > $@

build/plans.json: build/region.txt
	curl "https://api.vultr.com/v2/plans" > $@

build/region.txt: ../config.json build/.dir
	jq --raw-output '.vultr.principal_region' $< > $@

build/os_id.txt: build/os.json
	jq '.os[] | select(.family == "ubuntu")' $< \
		| jq --slurp 'max_by(.name).id' > $@

build/os.json: build/.dir
	curl "https://api.vultr.com/v2/os" > $@

build/.dir:
	mkdir -p build
	touch $@

# Destroy the runner only if it exists
# P -> Q == !P || Q
clean:
	(! $(MAKE) runner_exists) || $(MAKE) destroy_runner
	rm -rf build

VERSION:=1.12

test: fmt init validate

i init:
	terraform init

v validate:
	terraform validate

f fmt:
	terraform fmt

p plan:
	[ -e identity ] || ssh-keygen -t ecdsa -b 521 -N "" -C "test-key" -f identity
	[ -e known_hosts ] || touch known_hosts
	terraform plan $(PLAN_OPTIONS)

release:
	@if [ $$(git status --short | wc -l) -gt 0 ]; then \
		git status; \
		echo ; \
		echo "Tree is not clean. Please commit and try again"; \
		exit 1; \
	fi
	git pull --tags
	git tag v$(VERSION)
	git push --tags
	git push

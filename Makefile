generate-doc:
	terraform-docs markdown table --output-file README.md --output-mode inject .

.PHONY: format-tf
format-tf:
	terraform fmt -list=false
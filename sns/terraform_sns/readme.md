📂 terraform_project/
│── 📂 modules/
│   ├── 📂 input/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   ├── 📂 output/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   ├── 📂 compute/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│── main.tf
│── variables.tf
│── outputs.tf
│── provider.tf

terraform init -upgrade
terraform validate
terraform plan
terraform apply -auto-approve
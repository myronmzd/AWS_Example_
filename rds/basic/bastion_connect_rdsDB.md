# Connect to RDS from a Bastion Host

This guide explains how to connect to a PostgreSQL RDS instance from a bastion EC2 instance in the same VPC and subnet, including how to retrieve credentials from AWS Secrets Manager and run SQL commands.

---

## 1. Install PostgreSQL Client (if needed)

On Amazon Linux 2:
```sh
sudo amazon-linux-extras enable postgresql14
sudo yum clean metadata
sudo yum install postgresql14 -y
```

On Ubuntu:
```sh
sudo apt-get update
sudo apt-get install postgresql-client -y
```

---

## 2. Get the RDS Endpoint

You can get the endpoint from CloudFormation outputs or with the AWS CLI:
```sh
aws rds describe-db-instances --region ap-south-1 \
  --query "DBInstances[*].Endpoint.Address" --output text
```

---

## 3. Connect to RDS (with username and password)

```sh
psql -h <RDS_ENDPOINT> -U <DBUser> -d <DBName>
```
- Replace `<RDS_ENDPOINT>`, `<DBUser>`, and `<DBName>` with your actual values.
- You will be prompted for the password.

---

## 4. Using AWS Secrets Manager for Credentials

If your DB credentials are stored in AWS Secrets Manager:

```sh
# 1. Get the secret value (replace <SECRET_NAME> with your secret's name)
secret=$(aws secretsmanager get-secret-value --region ap-south-1 --secret-id <SECRET_NAME> --query SecretString --output text)

# 2. Extract username and password from the secret (requires jq)
db_user=$(echo "$secret" | jq -r .username)
db_pass=$(echo "$secret" | jq -r .password)

# 3. Get the RDS endpoint
rds_endpoint=$(aws rds describe-db-instances --region ap-south-1 --query "DBInstances[*].Endpoint.Address" --output text)

# 4. Connect to the database (PostgreSQL example)
PGPASSWORD="$db_pass" psql -h "$rds_endpoint" -U "$db_user" -d <DBName>
```

---

## 5. Example SQL Usage

Once connected, you can create tables and insert data:

```sql
CREATE TABLE public.cloud_instances (
    instance_id      serial PRIMARY KEY,
    name             text         NOT NULL,
    provider         varchar(10)  NOT NULL CHECK (provider IN ('AWS', 'Azure', 'GCP')),
    size             varchar(25)  NOT NULL,
    region           varchar(25)  NOT NULL,
    monthly_cost_usd numeric(10,2) NOT NULL CHECK (monthly_cost_usd >= 0),
    created_at       timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX idx_cloud_instances_provider_region
    ON public.cloud_instances (provider, region);

INSERT INTO public.cloud_instances
    (name, provider, size,        region,       monthly_cost_usd, created_at)
VALUES
    ('web-frontend', 'AWS',   't3.medium',     'us-east-1',    45.60,  '2025-06-01 10:14:00+00'),
    ('api-backend',  'GCP',   'n2-standard-4','us-central1', 110.50,  '2025-06-05 08:47:00+00'),
    ('data-warehouse','Azure','D16s_v5',       'eastus',      880.00,  '2025-06-10 15:23:00+00'),
    ('ml-training',  'AWS',   'g5.4xlarge',   'us-west-2',  1500.75,  '2025-06-18 13:05:00+00'),
    ('logging-node', 'GCP',   'e2-medium',    'europe-west1', 33.10,  '2025-06-20 11:42:00+00');

SELECT *
FROM   public.cloud_instances
ORDER  BY instance_id;
```

---

## 6. Example Output

```
[ec2-user@ip-10-0-1-86 ~]$ psql -h myrdsstack-mydb-catrprubjpxh.cx62i6e00r7z.ap-south-1.rds.amazonaws.com -U bob -d mydb
Password for user bob:
psql (14.18, server 17.4)
WARNING: psql major version 14, server major version 17.
         Some psql features might not work.
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256, bits: 128, compression: off)
Type "help" for help.

mydb=> SELECT * FROM public.cloud_instances ORDER BY instance_id;
 instance_id |      name      | provider |     size      |    region    | monthly_cost_usd |       created_at
-------------+----------------+----------+---------------+--------------+------------------+------------------------
           1 | web-frontend   | AWS      | t3.medium     | us-east-1    |            45.60 | 2025-06-01 10:14:00+00
           2 | api-backend    | GCP      | n2-standard-4 | us-central1  |           110.50 | 2025-06-05 08:47:00+00
           3 | data-warehouse | Azure    | D16s_v5       | eastus       |           880.00 | 2025-06-10 15:23:00+00
           4 | ml-training    | AWS      | g5.4xlarge    | us-west-2    |          1500.75 | 2025-06-18 13:05:00+00
           5 | logging-node   | GCP      | e2-medium     | europe-west1 |            33.10 | 2025-06-20 11:42:00+00
(5 rows)
```

---

## 7. Notes

- Make sure `jq` is installed for parsing JSON from Secrets Manager:
  ```sh
  sudo yum install jq -y   # Amazon Linux
  sudo apt-get install jq  # Ubuntu
  ```
- Replace placeholder values (`<RDS_ENDPOINT>`, `<DBUser>`, `<DBName>`, `<SECRET_NAME>`) with your actual values.
- If you see a version warning, it is safe to ignore unless you need advanced features.

---

**You are now ready to securely connect to your RDS instance from your bastion host and manage your database.**

# App

This folder contains reference source code for the application and database
placeholder used by the EC2 user data scripts.

The Terraform deployment embeds equivalent logic through:

- `terraform/scripts/app-user-data.sh`
- `terraform/scripts/database-user-data.sh`

## Application Endpoints

- `/`: returns an HTML page with instance details, private IP, database status, and health path
- `/health`: returns `ok`

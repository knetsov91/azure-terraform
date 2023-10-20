terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {

  features {}
}


resource "random_integer" "ri" {
  min = 10000
  max = 99999

}

resource "azurerm_resource_group" "ri" {
  name     = "${var.resource_group_name}${random_integer.ri.result}"
  location = var.resource_group_location
}


resource "azurerm_service_plan" "asp" {
  name                = "${var.app_service_plan}${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.ri.name
  location            = azurerm_resource_group.ri.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "alwa" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.ri.name
  location            = azurerm_resource_group.ri.location
  service_plan_id     = azurerm_service_plan.asp.id

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
}


resource "azurerm_app_service_source_control" "example" {
  app_id                 = azurerm_linux_web_app.alwa.id
  repo_url               = var.repo_url
  branch                 = "main"
  use_manual_integration = true
}
#"https://github.com/knetsov91/taskboard-softuni"

resource "azurerm_mssql_server" "sqlserver" {
  name                         = var.sql_server
  resource_group_name          = azurerm_resource_group.ri.name
  location                     = azurerm_resource_group.ri.location
  version                      = "12.0"
  administrator_login          = var.sql_administration_login_username
  administrator_login_password = var.sql_administration_login_password

  #  administrator_login          = "sa_kosio"
  #  administrator_login_password = "yourPassword1"

  tags = {
    environment = "production"
  }
}

resource "azurerm_mssql_database" "database" {
  name         = var.sql_database
  server_id    = azurerm_mssql_server.sqlserver.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"


  sku_name       = "S0"
  zone_redundant = false


}

resource "azurerm_mssql_firewall_rule" "example" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
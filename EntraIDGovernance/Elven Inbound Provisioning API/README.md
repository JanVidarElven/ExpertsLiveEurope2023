# Elven Inbound Provisioning API - Infrastructure as Code

This will deploy the resources needed for Elven Inbound Provisioning API.

PS! There are a lot of references to "Elven" in naming for resources here, make sure you fork this repo and change to your own values for resources and attributes.

## Running the bicep code

You can run the bicep code directly with the [Azure CLI](https://aka.ms/nubesgen-install-az-cli).
Make sure to have an up to date version - bicep support may not be present on older versions - and authenticate using `az login`.

You can also set which subscription to use with `az account set --subscription "<subscription name>"`

You can deploy your infrastructure with the following command. Please replace `{environment}` by the name of your environment.

```shell
az deployment sub create --name 'deploy-elven-inboundprovisioning-api-{environment}' --location norwayeast --template-file main.bicep
```

## Resources

### Bicep documentation

- [Bicep documentation](https://aka.ms/nubesgen-bicep-documentation)

### Azure naming conventions

- [Recommended abbreviations for Azure resource types](https://aka.ms/nubesgen-recommended-abbreviations)
- [Naming rules and restrictions for Azure resources](https://aka.ms/nubesgen-naming-rules)
- [Example names for common Azure resource types](https://aka.ms/nubesgen-caf-example-names)

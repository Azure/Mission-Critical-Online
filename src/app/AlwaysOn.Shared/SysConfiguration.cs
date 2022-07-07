using Microsoft.Extensions.Configuration;

namespace AlwaysOn.Shared
{
    public class SysConfiguration
    {
        #region constants

        // These constant values are also defined in the infrastructure (Terraform) templates. Make sure to change both locations if needed

        public const string ApplicationInsightsConnStringKeyName = "APPLICATIONINSIGHTS_CONNECTION_STRING";
        public const string ApplicationInsightsAdaptiveSamplingName = "APPLICATIONINSIGHTS_ADAPTIVE_SAMPLING";

        public const string CosmosCatalogItemsContainerName = "catalogItems";
        public const string CosmosItemCommentsContainerName = "itemComments";
        public const string CosmosItemRatingsContainerName = "itemRatings";

        public const string BackendStoragePoisonMessagesTableName = "backgroundProcessorPoisonMessages";

        public const string GlobalStorageAccountImageContainerName = "$web";
        /// <summary>
        /// Since the images are stored on a static-website-enabled storage account, we are serving them through a virtual path in Front Door
        /// </summary>
        public const string GlobalImagesPathSegment = "images";

        #endregion

        private readonly IConfiguration Configuration;
        public SysConfiguration(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        /// <summary>
        /// The Azure Region this application is running it. The format of this needs to be like "East US 2"
        /// If not supplied, defaults to "unknown"
        /// </summary>
        public string AzureRegion => !string.IsNullOrEmpty(Configuration["AZURE_REGION"]) ? Configuration["AZURE_REGION"] : "unknown";
        /// <summary>
        /// Short form of the AzureRegion setting. The format of this is like "eastus2"
        /// </summary>
        public string AzureRegionShort => AzureRegion.Replace(" ", "").ToLower();

        /// <summary>
        /// API Key for restricted APIs
        /// </summary>
        public string ApiKey => Configuration["API_KEY"];

        /// <summary>
        /// Connection string for the globally shared storage account which is used for catalog image storage
        /// </summary>
        public string GlobalStorageAccountConnectionString => Configuration["GLOBAL_STORAGEACCOUNT_CONNECTIONSTRING"];

        public string CosmosEndpointUri => Configuration["COSMOSDB_ENDPOINT"];
        public string CosmosApiKey => Configuration["COSMOSDB_APIKEY"];
        public string CosmosDBDatabaseName => Configuration["COSMOSDB_DATABASENAME"];

        public string FrontendSenderEventHubConnectionString => Configuration["FRONTEND_SENDEREVENTHUBCONNECTIONSTRING"];

        public string BackendReaderEventHubConnectionString => Configuration["BACKEND_READEREVENTHUBCONNECTIONSTRING"];
        public string BackendReaderEventHubConsumergroup => Configuration["BACKEND_READEREVENTHUBCONSUMERGROUPNAME"];
        public string BackendStorageConnectionString => Configuration["STORAGEACCOUNT_CONNECTIONSTRING"];
        public string BackendCheckpointBlobContainerName => Configuration["STORAGEACCOUNT_EHCHECKPOINTCONTAINERNAME"];

        /// <summary>
        /// Controls how often checkpointing on Blob Storage is executed. The more often this happens, the more overhead and thus slower the processing.
        /// But longer periods make for potential longer loss of progress tracking and thus more re-processing or duplicate processing.
        /// Default value is 10 secods.
        /// </summary>
        public int BackendCheckpointLoopSeconds
        {
            get
            {
                var value = Configuration["BACKEND_CHECKPOINT_LOOP_SECONDS"];
                return int.TryParse(value, out int result) ? result : 10;
            }
        }

        /// <summary>
        /// Default value is 30
        /// From: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/765dcc58cb14b3291bf9162f31b93bddcc2b5a82/Microsoft.Azure.Cosmos/src/CosmosClientOptions.cs#L247
        /// </summary>
        public double ComsosRetryWaitSeconds
        {
            get
            {
                var value = Configuration["COSMOS_RETRY_WAIT_SEC"];
                return double.TryParse(value, out double result) ? result : 30;
            }
        }

        /// <summary>
        /// Default value is 9
        /// From: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/765dcc58cb14b3291bf9162f31b93bddcc2b5a82/Microsoft.Azure.Cosmos/src/CosmosClientOptions.cs#L241
        /// </summary>
        public int ComsosMaxRetryCount
        {
            get
            {
                var value = Configuration["COSMOS_MAX_RETRY_COUNT"];
                return int.TryParse(value, out int result) ? result : 9;
            }
        }

        /// <summary>
        /// Default value is 30 (SDK default is 60)
        /// From: https://github.com/Azure/azure-cosmos-dotnet-v3/blob/765dcc58cb14b3291bf9162f31b93bddcc2b5a82/Microsoft.Azure.Cosmos/src/CosmosClientOptions.cs#L157
        /// </summary>
        public int ComsosRequestTimeoutSeconds
        {
            get
            {
                var value = Configuration["COSMOS_REQUEST_TIMEOUT_SECONDS"];
                return int.TryParse(value, out int result) ? result : 60;
            }
        }

        /// <summary>
        /// How often should the BackgroundProcessor retry to process an Event if processing fails, for example because CosmosDB is not available.
        /// Default: 10
        /// </summary>
        public int BackgroundProcessorMaxRetryCount
        {
            get
            {
                var value = Configuration["BACKGROUNDPROCESSOR_MAX_RETRY_COUNT"];
                return int.TryParse(value, out int result) ? result : 10;
            }
        }

        /// <summary>
        /// How long - exponentially - should the BackgroundProcessor wait between each retry if processing fails, for example because CosmosDB is not available.
        /// Default: 5
        /// </summary>
        public int BackgroundProcessorRetryWaitSeconds
        {
            get
            {
                var value = Configuration["BACKGROUNDPROCESSOR_RETRY_WAIT_SEC"];
                return int.TryParse(value, out int result) ? result : 5;
            }
        }

        public string HealthServiceStorageConnectionString => Configuration["STORAGEACCOUNT_CONNECTIONSTRING"];
        public string HealthServiceBlobContainerName => Configuration["STORAGEACCOUNT_HEALTHSERVICE_CONTAINERNAME"];
        public string HealthServiceBlobName => Configuration["STORAGEACCOUNT_HEALTHSERVICE_BLOBNAME"];
        public int HealthServiceCacheDurationSeconds
        {
            get
            {
                var value = Configuration["HEALTHSERVICE_CACHE_DURATION_SECONDS"];
                return int.TryParse(value, out int result) ? result : 10;
            }
        }
        public int HealthServiceOverallTimeoutSeconds
        {
            get
            {
                var value = Configuration["HEALTHSERVICE_OVERALL_TIMEOUT_SECONDS"];
                return int.TryParse(value, out int result) ? result : 20;
            }
        }

        /// <summary>
        /// Enable Swagger endpoint on the service?
        /// Defaults to true
        /// </summary>
        public bool EnableSwagger
        {
            get
            {
                var value = Configuration["ENABLE_SWAGGER"];
                return bool.TryParse(value, out bool result) ? result : true;
            }
        }
    }
}

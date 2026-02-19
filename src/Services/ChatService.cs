using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure.Identity;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatService> _logger;
        private readonly DefaultAzureCredential _credential = new();

        public ChatService(IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<ChatService> logger)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<string> SendMessageAsync(string userMessage)
        {
            var endpoint = _configuration["AzureAI:Endpoint"];
            var deploymentName = _configuration["AzureAI:DeploymentName"];

            if (string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(deploymentName))
            {
                throw new InvalidOperationException("AzureAI configuration is missing. Please set Endpoint and DeploymentName.");
            }

            var requestUrl = $"{endpoint.TrimEnd('/')}/openai/deployments/{Uri.EscapeDataString(deploymentName)}/chat/completions?api-version=2024-10-21";

            var requestBody = new
            {
                messages = new[]
                {
                    new { role = "system", content = "You are a helpful assistant for the Zava Storefront." },
                    new { role = "user", content = userMessage }
                },
                max_tokens = 800,
                temperature = 0.7
            };

            var token = await _credential.GetTokenAsync(
                new Azure.Core.TokenRequestContext(new[] { "https://cognitiveservices.azure.com/.default" }));

            var client = _httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            _logger.LogInformation("Sending chat request to Phi-4 deployment");

            var response = await client.PostAsync(requestUrl, content);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogError("AI endpoint returned {StatusCode}: {Error}", response.StatusCode, errorBody);
                throw new HttpRequestException($"AI service returned {(int)response.StatusCode}: {response.ReasonPhrase}");
            }

            var responseJson = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseJson);

            var assistantMessage = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            return assistantMessage ?? string.Empty;
        }
    }
}

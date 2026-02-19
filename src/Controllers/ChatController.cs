using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ILogger<ChatController> _logger;
        private readonly ChatService _chatService;

        public ChatController(ILogger<ChatController> logger, ChatService chatService)
        {
            _logger = logger;
            _chatService = chatService;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Message))
            {
                return BadRequest(new { error = "Message cannot be empty." });
            }

            if (request.Message.Length > 2000)
            {
                return BadRequest(new { error = "Message is too long. Maximum 2000 characters." });
            }

            try
            {
                _logger.LogInformation("Processing chat message");
                var response = await _chatService.SendMessageAsync(request.Message);
                return Json(new { response });
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Chat service configuration error");
                return StatusCode(500, new { error = "Chat service is not configured. Please contact an administrator." });
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Error communicating with AI endpoint");
                return StatusCode(502, new { error = "Failed to get a response from the AI service. Please try again later." });
            }
        }
    }

    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
    }
}

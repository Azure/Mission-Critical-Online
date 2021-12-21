using System.ComponentModel.DataAnnotations;

namespace AlwaysOn.Shared.Models.DataTransfer
{
    public class NewCommentDto
    {
        [Required]
        public string AuthorName { get; set; }

        [Required]
        public string Text { get; set; }
    }
}

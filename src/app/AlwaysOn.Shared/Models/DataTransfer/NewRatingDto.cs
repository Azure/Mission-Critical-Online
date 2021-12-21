using System.ComponentModel.DataAnnotations;

namespace AlwaysOn.Shared.Models.DataTransfer
{
    public class NewRatingDto
    {
        [Required]
        public int Rating { get; set; }
    }
}

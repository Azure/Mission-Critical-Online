using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Models
{
    [Table("Ratings", Schema = "ao")]
    public class ItemRating : AoSqlModelBase
    {
        public Guid RatingId { get; set; }
        public Guid CatalogItemId { get; set; }
        public int Rating { get; set; }

        //[JsonIgnore]
        //[ForeignKey(nameof(CatalogItemId))]
        //public CatalogItem Item { get; set; }
    }

    [Table("AllActiveRatings", Schema = "ao")]
    public class ItemRatingRead : ItemRating { }
}

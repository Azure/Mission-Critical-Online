using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace AlwaysOn.Shared.Models
{
    public class CatalogItem : AoSqlModelBase
    {
        public Guid CatalogItemId { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string ImageUrl { get; set; }
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }
        public DateTime LastUpdated { get; set; }
        public double? Rating { get; set; }

        // we are not currently fetching these along with the item, so no need to have them empty in the JSON response
        //[JsonIgnore]
        //public List<ItemComment>? Comments { get; set; }
        //[JsonIgnore]
        //public List<ItemRating>? Ratings { get; set; }
    }

    [Table("CatalogItems", Schema = "ao")]
    public class CatalogItemWrite : CatalogItem { }
    
    [Table("LatestActiveCatalogItems", Schema = "ao")]
    public class CatalogItemRead : CatalogItem { }

}

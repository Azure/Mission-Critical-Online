using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace AlwaysOn.Shared.Models
{
    //
    // Base class has to be defined without the [Table] attribute.
    // Entity Framework follows class inheritance -> 
    //  If CatalogItem would be tied to the [CatalogItems] table and CatalogItemRead to the [LatestActiveCatalogItems] view and derived from CatalogItem,
    //  it would combine both the db table and the db view in the query.
    //
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
    }

    // This is an actual database table.
    [Table("CatalogItems", Schema = "ao")]
    public class CatalogItemWrite : CatalogItem { }
    
    // This is a database view.
    [Table("LatestActiveCatalogItems", Schema = "ao")]
    public class CatalogItemRead : CatalogItem { }

}

using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace AlwaysOn.Shared.Models
{
    [Table("Comments", Schema = "ao")]

    public class ItemComment : AoSqlModelBase
    {
        public Guid CatalogItemId { get; set; }
        public string AuthorName { get; set; }
        public string Text { get; set; }

        [JsonIgnore]
        [ForeignKey(nameof(CatalogItemId))]
        public CatalogItem Item { get; set; }
    }

    [Table("AllActiveComments", Schema = "ao")]
    public class ItemCommentRead : ItemComment { }
}

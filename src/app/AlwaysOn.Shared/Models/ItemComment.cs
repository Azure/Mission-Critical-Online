using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace AlwaysOn.Shared.Models
{
    public class ItemComment
    {
        public Guid Id { get; set; }
        public Guid CatalogItemId { get; set; }
        public string AuthorName { get; set; }
        public string Text { get; set; }
        public DateTime CreationDate { get; set; }

        /// <summary>
        /// Time to live in Cosmos DB. In Seconds
        /// </summary>
        [JsonPropertyName("ttl")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        public int? TimeToLive { get; set; }
    }
}

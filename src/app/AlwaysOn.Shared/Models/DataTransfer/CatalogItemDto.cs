using System;

namespace AlwaysOn.Shared.Models.DataTransfer
{
    public class CatalogItemDto
    {
        /// <summary>
        /// Optional Guid. Can be set on POST requests to create/upsert items with a specific ID.
        /// Mostly used for data import
        /// </summary>
        public Guid? Id { get; set; }
        public string Name { get; set; }

        public string Description { get; set; }

        public string ImageUrl { get; set; }

        public decimal? Price { get; set; }
    }
}

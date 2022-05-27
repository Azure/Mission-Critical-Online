#nullable disable // from sample: https://github.com/Azure-Samples/dotnetcore-sqldb-tutorial/blob/master/Data/MyDatabaseContext.cs
using AlwaysOn.Shared.Models;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace AlwaysOn.Shared
{
    public class AoDbContext : DbContext
    {
        public AoDbContext(DbContextOptions options) : base(options) { }

        public DbSet<CatalogItemRead> CatalogItemsRead { get; set; }
        public DbSet<CatalogItem> CatalogItemsWrite { get; set; }

        public DbSet<ItemCommentRead> ItemCommentsRead { get; set; }
        public DbSet<ItemComment> ItemCommentsWrite { get; set; }

        public DbSet<ItemRatingRead> ItemRatingsRead { get; set; }
        public DbSet<ItemRating> ItemRatingsWrite { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            //modelBuilder.Entity<AllCatalogItems>(eb =>
            //{
            //    eb.HasNoKey();
            //    eb.ToView("AllCatalogItems");
            //});
        }
    }
}
